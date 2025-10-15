+++
date = '2025-03-14T11:12:39+01:00'
draft = true
title = 'ATproto in a nutshell'
+++

**ATproto** is somewhat of a new communication protocol for the social internet layer. I have originally first heard about it when a lot of users pivoted to alternative platforms during the Elon Musk takeover of Twitter. Back then, the social media platform **Bluesky** gained a lot of traction for picking up these users into their new ATproto-based platform.

This week, I have started to read more about it an started to listen some podcasts about its core functionality. And I must say, that I really like this protocol! Actually I like it so much, that I want to outline the core functionality and usecases of **ATproto** in this post.

First of all, what does **ATproto** mean. ATproto stands for **Authenticated Transfer Protocol** and it was developed and standardized by **Bluesky Social PBC** in order to create a decentralized, interopable and secure protocol for their social-media platform called **Bluesky**. 

To understand ATproto properly, we need to understand the current state of the internet. The development phases of the internet is commonly divided in three or more phases. The first one is called **Web1**.

## Web1.0

Web1.0 refers to the earliest version of the internet, often called the "read-only" web. This period, which lasted from the early 1990s to the early 2000s, was characterized by simple, static websites that provided basic information. Users could only view content but had little interaction with it. Websites were created using HTML and consisted of text, images, and links. Web1 was largely a one-way communication medium, where businesses and individuals posted content, and users accessed it passively.

## Web2.0

Web2.0 marked a major shift toward an interactive, dynamic internet experience. It began in the early 2000s and is still the dominant form of the internet today. This era is defined by the rise of social media, user-generated content, and platforms that allow individuals to interact, share, and create. Web2 is the "read-write" web, where users not only consume information but also contribute to it. Examples include platforms like Facebook, Twitter, YouTube, and Instagram, where users create profiles, share media, and communicate.

## Web3.0

Web3.0 represents the next phase of the internet, driven by blockchain technology, decentralization, and the idea of "ownership" over personal data and content. Unlike Web2, where centralized platforms control user data, Web3 envisions a more open and peer-to-peer internet. This era is characterized by decentralized applications (dApps), cryptocurrencies, and decentralized finance (DeFi). Users are empowered to control their own data, transact securely, and engage in online communities without relying on central authorities. I would classify **ATproto** as a protocol operating on Web3.0 but without utilizing blockchain technology while still having decentralization and security at its front and center. 

## What does ATproto?

Now that we fully understood the history and evolution of the internet, we can go on to explore the functionality and uses of ATproto. At its core, ATproto is a protocol that enables different social-media platforms operate in a decentralized, interconnected and interopable network that is openly governed, freely accessible and where, most-importantly data is **owned by the users in a cryptographically verifiable way**. ATproto enables platforms like Bluesky to let the users freely decide what happens with their data (where is it stored, who hosts it). Moreover accessibility on ATproto is permanent and secure.

## ATproto Features

ATproto has a lot of cool features that left me speechless at first. 

## ATproto Components

## My Ideas and Extensions

### Inter-PDS Danksharding for data repos

### Fogmode

### TEE based PDSs

---



---- main features ----

- portability: once you create an account (DID) on bluesky or anywhere on ATproto, you can move your data around other platforms on ATproto without loosing posts, followers or other data.
- decentralized with federation
- opensource algorithms
- no centralized moderation / no single-point of moderation
- interopability: platforms and apps on ATproto can talk to each other and share data interchangibly
- no single-point of failure -> more resilient to cyber attacks

---- key components ----

### Decentralized Identity (DID:PLC)
  Decentralized Identity - Persistent Linked Cryptography
  - permanent owned account
  - not controlled by a central identity
  - DID is always permanent and immutable even if you leave apps like bsky


## Personal Data Server (PDS)
  server where all your posts, profile, social data, and more are stored.
  - you can selfhost or use as a service an an app / platforms
  - instead of the platform controlling where your data is sent, you can choose where to host your data
  - similar to cloud-storage

## Lexicons
  rules that define how ATproto platforms and apps talk to each other. 
  standardized way to structure data in 
  - prevents protocol fragmentation where apps and protocols are fragmented and isolated. -> everything is interconnected in ATproto
  - devs can use and create new lexicons to change the way apps work
  - lexicon is similar to HTML. where a website is similar to an app and the browser is similar to ATproto.
    - we can add new features to the website while the browser still understands HTML.
    - ATproto Lexicons does same for socialmedia

## Repositories
  logbook that keeps track of all posts, interactions, profile changes and more dynamic content
  every user has an own repository that stores their signed data 
  - your data is cryptographically signed
  - repositories are not stored centrally. so they can be verifiable and usable across the whole ATproto ecosystem.
  - similar to a blockchain for dynamic but personal social media content
