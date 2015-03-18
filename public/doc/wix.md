# windex
`windex` is a collaborative project (proposal).


## What is it?
`windex-server` is literally a _tracker_ of files. Its purpose is to track files. The server does not store any file, but a file identifier - in the current prototype this is a tuple `(size, sha2-512)`.

Users can tell to the system that some file `f` has existed.
Additionally they can associate a `filename`, a `timestamp` (think about `mtime` or when the user accessed `f`), or a flag to indicate if they own `f` at that moment to a `f`.
Users can also associate a `f` to one of theirs `sub index`.


## What is it for?
The main purpose is just build a index of file identifiers.

Another  is track the `live` of the files (a cyber graveyard/certificate of birth).

Anything is a file: a url is a file, a response of a server to some url is a file, even if different requests produce different responses.
What'd be the system useful is build an ontology of such files.
Such ontology would mainly be populated by programs (daemons, bots, ...) by relating files like `(f1, f2, f3)` where `f3` is the output of executing `f1 < f2`  (such relation is also a files).
Of course, such ontology could also relate files to resources (such as urls), so even if `f1` cannot be retrieved, maybe `f3` can be retrieved.

If the ontology is heavy popullated, given a file `f` you could look at the ontology what's the file type (`/usr/bin/file` output), the crc, or whathever.


## How it works?
There's a client `wix` that allows the users to track their local files in a way very likely to `git`. You can select what folders of filenames you'd like to publish, ignore some of them, when you want to add, when you want to take a snapshot (commit) of that `local sub index` and went you want to push that snapshots to the server.


## FAQ

### Can I retrieve the files?
The server does not provide a way to retrieve the files. However, users can associate a file to a public sub index, which can have associate an email (it's up to the user what data he want publish), so it could provide a way to discover emails that claim to have own a file.


## TODO
If the server does not reveal the identifier of a file only users that had such file can identify them.
Actually, the server could not store at all any identifier, but a hash of the `(size, sha2-512)`.
