Chessboard
==========

Chessboard is a bulletin-board forum for the world wide web. It is
*not* built on top of PHP, has a clean codebase and only aims to serve
the sole purpose of a simple forum software, albeit containing often
requested features. It was born because I strongly dislike PHP
software, and I did not have the ability to host the extremely
resource-hungry [Discourse](http://disource.org) forum software, which
also makes extreme use of JavaScript.

Chessboard is written in Ruby, with help of the
[Padrino](http://padrinorb.com) web framework in order to stay as
lightweight as possible.

Note that Chessboard is not a Rails/Padrino engine. It is not meant to
be included in an existing web application, but instead to be run as
an application on its own. Check the
[RubyToolbox](https://www.ruby-toolbox.com/categories/forum_systems)
if that was what you’re looking for.

This is currently a development version. Do not use if you don’t know
what you do.

Setup
-----

Only development-mode setup currently.

~~~~~~~~~~~~~~~~~~~~~
$ bundle install
$ bundle exec rake ar:create ar:schema:load db:seed
~~~~~~~~~~~~~~~~~~~~~

In order to use the development-mode mailer, you have to install the
[Mailcatcher](http://mailcatcher.me) gem and run the Mailcatcher
daemon:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ gem install mailcatcher
$ mailcatcher
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Now start the server:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ bundle exec padrino s
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

There are two user accounts you can log into: `admin`, with password
`adminadmin`, and `user`, with password `useruseruser`. `admin` has
complete administrative rights, `user` is a normal board member.

Emoticons
---------

You can easily add new emoticons by just dropping them into the
`public/images/emoticons/default` folder, just ensure they are in GIF
format and their filenames are all lowercase. They will automatically
be picked up on the next restart of Chessboard.

License
-------

Chessboard is a bulletin-board forum for the world wide web.

Copyright © 2014  Marvin Gülker

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
