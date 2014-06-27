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

This is currently a development version. Do not use if you don’t know
what you do.

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
