# PROCTOR

Proctor is a service to manage SSH keys for individuals and teams. Imagine that you have to provision a set of servers with different access depending of the purpose of each server. You can add the keys of all your developers and siteops in the service, group them by teams (e.g: developers, sitepos, datascience) and make your provision system to fetch the keys by team whenever a new server is up.

This is mostly an idea of how a small service for provisioning could be.

## Setup

First clone the repo:

```shell
$ git clone https://github.com/jhbabon/proctor.rb.git /path/to/app
```

And install all gems. The project has been only tested against ruby `2.2.2`:

```shell
$ cd /path/to/app
$ bundle install --without=test development
```

Proctor needs the environment for the configuration. These are the environment variables that needs to be set:

- `RACK_ENV`: The environment for the app. If not set is `development` by default.
- `PROCTOR_DATABASE_URL`: The URL to the database. Proctor works with SQLite, so a valid url would be like `sqlite3:/path/to/proctor.sqlite3`
- `PROCTOR_ADMIN_USERNAME`: This is the default admin of the app. If there are no users in the system, it will be created at boot time.
- `PROCTOR_ADMIN_PASSWORD`: All users need a password.

You can put the `PROCTOR_*` variables in a `.env` file an the app will load them. You can see an example of this file in `.env.sample`.

Once you have the database set, you can create it:

```shell
$ RACK_ENV=production bundle exec rake db:create db:migrate
```

And, finally, you can run the app. `puma` is already a dependency, but this is a `sinatra` app, so any rack based server would work:

```shell
$ RACK_ENV=production bundle exec puma
```

## Usage

Proctor allows you to create users, ssh keys (a.k.a. pubkeys) associated to them, and teams to group these users.

For now on I would use the default admin as `hal@9000` to make calls against the API.

### Users

The users have three attributes:

- `name`: It will be used as an identifier, so it needs to be unique and URL friendly.
- `password`: For HTTP Basic authentication.
- `role`: Level of permissions.

A user can have the roles:

- `admin`: It can do everything.
- `user`: It can read everything. It can update itself and create and manipulate its own pubkeys.
- `guest`: It can only read.


#### `POST /users`

You can create your first user using:

```shell
$ curl -X POST -H 'Accept: application/json' "http://hal:9000@localhost:9292/users" -d '{"name":"batman","password":"imbatman","role":"user"}' | python -m json.tool
{
    "name": "batman",
    "role": "user"
}
```

#### `GET /users`

You can see any in the general users index

```shell
$ curl -X GET -H 'Accept: application/json' "http://hal:9000@localhost:9292/users" | python -m json.tool
[
    {
        "name": "batman",
        "role": "user"
    },
    {
        "name": "hal",
        "role": "admin"
    }
]
```

#### `GET /users/:name`

You can only one user

```shell
$ curl -X GET -H 'Accept: application/json' "http://hal:9000@localhost:9292/users/batman" | python -m json.tool
{
    "name": "batman",
    "role": "user"
},
```

#### `PATCH /users/:name`

The admin can update any user using:

```shell
$ curl -X PATCH -H 'Accept: application/json' "http://hal:9000@localhost:9292/users/batman" -d '{"name":"dark-knight"}' | python -m json.tool
{
    "name": "dark-knight",
    "role": "user"
}
```

And a user can update itself:

```shell
$ curl -X PATCH -H 'Accept: application/json' "http://dark-knight:imbatman@localhost:9292/users/dark-knight" -d '{"name":"batman","password":"imtherealbatman"}' | python -m json.tool
{
    "name": "batman",
    "role": "user",
}
```

The only restriction a user has when updating its data is that it cannot change the `role`. You cannot promote yourself.


#### `DELETE /users/:name`

For deleting, use the `DELETE` HTTP action:

```shell
$ curl -X DELETE -H 'Accept: application/json' "http://hal:9000@localhost:9292/users/batman"
< HTTP/1.1 204 No Content
```

### Teams

A team is the unit used to group users. It needs a `name` following the same format as the users.

#### `POST /memberships` & `DELETE /memberships`

Teams are created the first time when a user becomes a member of them. To create a membership you can do the following:

```shell
$ curl -X POST -H 'Accept: application/json' "http://hal:9000@localhost:9292/memberships" -d '{"team":"jla","user":"batman"}'
< HTTP/1.1 201 Created
```

You can also remove users memberships

```shell
$ curl -X DELETE -H 'Accept: application/json' "http://hal:9000@localhost:9292/memberships" -d '{"team":"jla","user":"batman"}'
< HTTP/1.1 204 No Content
```

#### `GET /teams`

You can get all the teams in the system with their users.

```shell
$ curl -X GET -H 'Accept: application/json' "http://hal:9000@localhost:9292/teams" | python -m json.tool
[
    {
        "name": "admins",
        "users": [
            "hal"
        ]
    },
    {
        "name": "jla",
        "users": [
            "batman"
        ]
    }
]
```

#### `GET /teams/:name`

You can also get a specific team

```shell
$ curl -X GET -H 'Accept: application/json' "http://hal:9000@localhost:9292/teams/jla" | python -m json.tool
{
    "name": "jla",
    "users": [
        "batman"
    ]
}
```

#### `GET /users/:name/teams` & `GET /teams/:name/users`

A user can belong to more than one team, and you can check it:

```shell
$ curl -X GET -H 'Accept: application/json' "http://hal:9000@localhost:9292/users/batman/teams" | python -m json.tool
[
    {
        "name": "jla"
    },
    {
        "name": "gotham"
    }
]
```

You have also the inverse relation:

```shell
$ curl -X GET -H 'Accept: application/json' "http://hal:9000@localhost:9292/teams/jla/users" | python -m json.tool
[
    {
        "name": "batman",
        "role": "user"
    },
    {
        "name": "superman",
        "role": "user"
    }
]
```

#### `DELETE /teams/:name`

You can get rid of whole teams the usual way:

```shell
$ curl -X DELETE -H 'Accept: application/json' "http://hal:9000@localhost:9292/teams/gotham"
< HTTP/1.1 204 No Content
```


### Pubkeys

SSH public keys, or `pubkeys` here, are the main reason behind this small service. A pubkey consist in:

- `title`: How are you going to refer to this key. Follows the same rules as the users' name.
- `key`: The actual content of a public key, like that one you have in `~/.ssh/id_rsa.pub`. This content is passed as plain text.

#### `POST /users/:name/pubkeys`

A user or an admin can add a key using `POST`:

```shell
$ curl -X POST -H 'Accept: application/json' "http://hal:9000@localhost:9292/users/batman/pubkeys" -d '{"title":"cave","key":"ssh-rsa AAAA bruce.wayne@cave.local"}' | python -m json.tool
{
    "key": "ssh-rsa AAAA bruce.wayne@cave.local",
    "title": "batman@cave"
}
```

#### `GET /users/:name/pubkeys` & `GET /users/:name/pubkeys/:title`

Once created, you can retrieve the keys:

```shell
$ curl -X GET -H 'Accept: application/json' "http://hal:9000@localhost:9292/users/batman/pubkeys" | python -m json.tool
[
    {
        "key": "ssh-rsa AAAA bruce.wayne@cave.local",
        "title": "batman@cave"
    }
]

$ curl -X GET -H 'Accept: application/json' "http://hal:9000@localhost:9292/users/batman/pubkeys/cave" | python -m json.tool
{
    "key": "ssh-rsa AAAA bruce.wayne@cave.local",
    "title": "batman@cave"
}
```

#### `PATCH /users/:name/pubkeys/:title`

You can update any key at any time:

```shell
$ curl -X PATCH -H 'Accept: application/json' "http://hal:9000@localhost:9292/users/batman/pubkeys/cave" -d '{"key":"ssh-rsa CCC bruce.wayne@dark.place"}' | python -m json.tool
{
    "key": "ssh-rsa CCC bruce.wayne@dark.place",
    "title": "batman@cave"
}
```

#### `DELETE /users/:name/pubkeys/:title`

You can delete any key:

```shell
$ curl -X DELETE -H 'Accept: application/json' "http://hal:9000@localhost:9292/users/batman/pubkeys/cave"
< HTTP/1.1 204 No Content
```


#### `GET /teams/:name/pubkeys`

This is probably the most important feature. You are able to get all the keys of a given team:

```shell
$ curl -X GET -H 'Accept: application/json' "http://hal:9000@localhost:9292/teams/jla/pubkeys" | python -m json.tool
[
    {
        "key": "ssh-rsa AAAA bruce.wayne@cave.local",
        "title": "batman@cave"
    },
    {
        "key": "ssh-rsa MMMM bruce.wayne@mansion.local",
        "title": "batman@mansion"
    },
    {
        "key": "ssh-rsa MMMM kal.el@krypton.local",
        "title": "superman@krypton"
    }
]
```

With this you would be able to set up the SSH access of one machine with one call.


## Development & tests

The setup for development is the same as described in the setup section. I recomend to use a database like:

```
PROCTOR_DATABASE_URL="sqlite3:db/development.sqlite3"
```

To run the tests you need to setup the database first and then run the tests:

```shell
$ bundle exec rake db:test:setup
$ bundle exec rake test
```

The test environment uses the config in `.env.test`.
