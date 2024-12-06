+++
title = "Analysing a new NOBELIUM/APT29 sample"
date = 2024-12-06T16:04:46+01:00
+++

As how often I do, I stumbled upon a very interesting malware sample on [abuse.ch](https://bazaar.abuse.ch). I usually just look for malware samples from high-profilic threat-actors and advanced persistent threats (APTS).

![alt](/sample.png)

After taking a closer look to the sample, I figured out, that it is a new malware sample originating from the prevalent advanced threat actor called NOBELIUM. NOBELIUM is also known under the names YTTERBIUM, MIDNIGHT BLIZZARD and APT29. You might also know it as Cozy Bear. NOBELIUM is also apparently one of worlds most sophisticated and dangerous threat actor, beeing nation/state-backed by Russia.

I then quickly downloaded the sample down to my detonation chamber. The initial sample is a HTML5 file with a JS script block. The JS script is roughly 21k lines of code and somewhat obfuscated. 