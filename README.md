﻿
<!--#echo json="package.json" key="name" underline="=" -->
safer-multimc-pmb
=================
<!--/#echo -->

<!--#echo json="package.json" key="description" -->
My attempt to jail MultiMC, the alternative Minecraft launcher.
<!--/#echo -->



Privacy Notice
--------------

The installer in this repo tries to disable MultiMC's analytics,
including the wall of text
that you would have been presented with on first launch.
Please ensure you know all information relevant to you,
and review the analytics settings to ensure they are what you expect.




Motivation
----------

I tried running Minecraft on Ubuntu, but the original launcher required
`gnome-keyring` to remember my login.
That, however, would have caused annoying popups from some unrelated,
badly programmed 3rd party software.
Using an alternate launcher seemed like an easy way out.
[MultiMC5](https://github.com/MultiMC/MultiMC5)
seemd to be the perfect choice from a modding perspective.
Its source code however, made me worry about my system integrity.
I tried contacting the devs to offer help, but that turned out too cumbersome.
A few thoughts later, I decided I wouldn't want to trust Mojang with my
system integrity either.
This sandbox game belongs inside a sandbox.



Prior work
----------

[Chad Miller](https://github.com/chadmiller/) provides some AppArmor profiles
for the vanilla launcher in his project
[minecraft-linux-support](https://github.com/chadmiller/minecraft-linux-support),
but those expect Minecraft to operate within certain predictable paths.
This would conflict with supporting some mods that are designed to operate
on files in unpredictable locations, so unfortunately the MultiMC devs
[cannot use that](https://github.com/MultiMC/MultiMC5/issues/1519).



Installation
------------

```bash
# Remove potential remains of the old MultiMC install:
rm --one-file-system --recursive -- multimc/

# Download and install the latest supported MultiMC:
./smmc.sh install_multimc

# If you don't have the user account yet, create it:
./smmc.sh reinstall_user_account

# Launch MultiMC:
./smmc.sh launch_multimc
```






<!--#toc stop="scan" -->



Known issues
------------

* Needs more/better tests and docs.




&nbsp;


License
-------
<!--#echo json="package.json" key=".license" -->
ISC
<!--/#echo -->
