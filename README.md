# alpine-sftp - Simple SFTP single-user access

This small SFTP container allows you to provide some simple & secure FTP access
to a user in a chroot'ed directory of your choosing. This helps you to provide
quick & easy access to things like: website assets directories, document
storage areas etc.

By default, an `sftp` user is created upon running a `docker build`, with a
UID/GID of 1000 and a volume exposed at `/sftp`.

**Helpful tip:** make sure to always build with --no-cache as this will ensure
that a new password is generated each time and printed out as part of the
build process.

The recommended default build command is:

`docker build --no-cache -t alpine-sftp .`


## Important

When preparing the directory you'll associate with the `/sftp` volume
(e.g., -v /my/website/assets:/sftp), make sure the directory is owned root:root
and that permissions are chmod'd 755.

If you do not, the SSH daemon will not allow you to login with your sftp user
due to bad ownership/permissions issues, or you will be able to login but not
get a directory listing.

e.g., when running container with `/usr/sbin/sshd -D -E /sshd.log`
```
...
Accepted password for sftp from 172.17.0.1 port 57022 ssh2
bad ownership or modes for chroot directory "/sftp"
```

All subsequent directories should have the same UID/GID ownership to that of
the sftp user set in this image, so that you can read/write those files &
directories as required.


## Running

In all likelihood, you are already running an SSH service on port 22, so often
the best way to run the SFTP service is by publishing on another port, like so:

`docker run -d -p 2222:22 -v /my/website/assets:/sftp alpine-sftp`

`-p 2222:22` simply publishes this service on port 2222 instead of the default
port 22 so it does not conflict with your existing SSH service.

**Helpful tip:** should you be having problems logging into SFTP once its
running, you can debug what's going on by running the following command on the
end of your `docker run` command:

`docker run -d ... alpine-sftp /usr/sbin/sshd -D -E /sshd.log`

... then shell into the running container and `tail` the log and see if it's
printing anything useful out when you attempt to login:

`docker exec -it name-of-your-container sh`

`tail -f -n 100 /sshd.log`

This will print out any activity as you attempt to login, helping you to debug
why your SFTP service isn't letting you in (usually ownership/permission
issues).


## Customising your username & UID/GIDs

Should you need to modify the username or its UID/GID you can via providing the
following build arguments:

* SFTP_UID
* SFTP_GID
* SFTP_USERNAME

(e.g. `docker build --no-cache -t alpine-sftp --build-arg="SFTP_USERNAME=bob" .`)

You may also need to configure the SFTP_UID & SFTP_GID values in the case that
they do not match those of your other systems.

(e.g., your apache container has a www-data user/group with a UID of 501, and a
GID of 500 and you want to provide SFTP access to read/write this data)

`docker build --no-cache -t alpine-sftp --build-arg="SFTP_UID=501" --build-arg="SFTP_GID=500" .`

**Note:** the only UID/GID's you'll have issues with are 0 and 22, the root &
sshd users respectively.


## Updating the SFTP password

If you need to rotate the SFTP password due to personnel changes or as part of
your organisation's security policies, as long as you re-build with --no-cache
the system will generate a fresh password along with the new container image.

We would recommend in any case that the image is regularly re-built so you get
any security updates available.


## "I cannot SSH in with the SFTP user"

No, you cannot. This image is meant purely for SFTP access and nothing more.
You will not be able to SSH into the container or forward traffic etc.


## "The password is rather long, can I have an easier password?"

The password is currently generated using `pwgen` which provides a long, secure
password. We would strongly recommend that instead of weakening the password
that anyone who needs access, employs the use of a password manager to safely
store & retrieve passwords as needed.


## "Why don't I just configure my SSH service directly for SFTP access?"

Of course you could configure your own SFTP-only user directly on what would be
the host system. But it's an extra pain, especially when configuring more
ephemeral, cloud-based instances.

This container also provides some extra protection in the case that its SSH
service was hacked and/or the user managed somehow to break out of its chroot
jail, as they would still only be in the confines of a very limited container.


## Improvements

Please feel free to provide any improvements you think can be made by way of
pull requests. For now the aim of this image is to provide a tiny, single-user
SFTP access and nothing more.

If you notice any further security measures that can be added to further harden
this service, please feel to let me know or contribute directly.
