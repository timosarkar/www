+++
title = "Hello world once again!"
date = 2024-12-06T09:40:42+01:00
+++

Hello world once again from my new blog. I recall rebuilding my blog for atleast 20 times the last few years. This time I use the [Hugo static-site generator](https://gohugo.io) to build my HTML page.
As usually, I write content in form of Markdown which is a simple and very lightweight markup language that allows you to write content in plaintext instead of cluttered HTML.

The stylesheet of this blog is stripped down to the bare minimum and will most likely fit easily into your businesscard. The raison-d'etre is my obsession with [brutalist- and minimalist webdesign](https://brutalistwebsites.com/). I think that when you want your target audience to really focus on your content, then you should make your site as accessible and easy to read as possible. Also this site does not collect data nor any types of analytical data or cookies from you.

> Note: The design for this blog is based almost 100% on the design that Vitalik Buterin (Founder of Ethereum) uses on his page. Tho I am using a different way to generate my pages and handle contents. All props go to Vitalik for this slick design. Check out his page: https://vitalik.eth.limo

I use [vercel](https://vercel.io) as my CI/CD (continuos integration / continuous delivery) platform which is cloud-based and allows me to initiate deployment processes for this site from anywhere and at anytime for free.

Currently, I use the [Nix package-manager](https://nixos.org) to manage my local builds so I can always trust on my nix-shell to use the pre-defined version of Hugo and not break my current infra.

All pages on this website are signed using my **PGP** (Pretty-Good Privacy) public key. The signatures are usually always at the bottom of the page. You can verify the authenticity of these posts by importing my public key and then checking againg the signatures that you will find in each post. Simply download the signature, install **PGP** and then run this command in your shell, assuming the binaries for PGP are in your **$PATH** environment variable.

```
gpg --verify <signature> <post>
```

Please find my public key here:

```
-----BEGIN PGP PUBLIC KEY BLOCK-----

mQGNBGeD1mwBDACp8xVTZYIJoEKo+Jw6vDQ3fuT7KyDQGnbi9hBSirKRe8BgsUyv
y0zkhxhuP7R6+hrNq53VHOBVRrLuomuXyyvY23wERgf01bB7946wAB9KadmaQqGB
KLdoI/wsvMcypW4c4j61UVU3LKqZlOYGRri5quwB/97jSgJ+TOb51h4SPfirVL1G
wBLSSbj2mOTj6pU5nUgTr698yIXHWEHhSHNrVfobtqOhDrUrXMiIdHLV+vo/y7xz
vFLfQc0elYj3R8J13/5kKX/GTQ7PM+GZZUUNbNfv/VQIY4DF1nN+u6sBcVNapxCY
rJC4Fm09BVPWyQm9qDvXLVfGtPcIZpNHyMYNaWteMdyVXlPV3ob7pLz8S8uNX1jx
t3V0wRcHI+3lE0p154FDvV0tJKmP3A58ewA12rOxnTETEDUuvLowgfTqaA+lIIc3
+EKAG/7gn9bE879mn/s5Qwv812YgCmuTf8lzypWB2Pxx4MC7aZBMTkdmCBsF7ym0
xGhipEArPeCaRFsAEQEAAbQhVGltbyBTYXJrYXIgPHNhcnRpbW8xMEBnbWFpbC5j
b20+iQHRBBMBCAA7FiEEsHVaS9uAMbMp+vMTaVlPKguqAwIFAmeD1mwCGwMFCwkI
BwICIgIGFQoJCAsCBBYCAwECHgcCF4AACgkQaVlPKguqAwKbbAv9GdlW+GJ2vqsR
XMN3poAIgrO15KgTGIIDreGTuVh0rbKh3EdTYiSllXXrsR/0VafAHMbheRr9kIwB
Fsh8bcMIsVlX3p4Ki1tpb0UdJaSZR9BBYE+GB6QAACgH12NWBtCdawWFwic/fF2/
SCOxUnwfOeJkAfUpgLRyrrhFG7m5WYKa/esxlvXD/qvhHtY5IyfJJz4vfFwoXYrh
dBPbkED4xN0qlwE0Ypwk5lAqJfuAkQpDVRpy34lg0qPc0/oX29h+uf/63mMn5Nr5
7sVT1RoMlEnJ63fwyjLYCSZ7+j/iajXzb4LhdfQ0YmDQeacJxplkjxwMDrWVH7L7
T7TwevzjNLkbuVphVQqNrQTJUURxu25dGncA7n8aVW05pzg/jGd7Zofw0YSN3ps+
7IUvWnEeHSGx051D7kdH0OqvZggY8S4j9t4A40lbP9DzAkhgDcaGV7I7UBHHE/L9
6TH1hUs4IUemJMaL6sxaIonlVH2fOc5qfIpTtB5o0eNYXe5j67oT
=8yT+
-----END PGP PUBLIC KEY BLOCK-----
```