---
title: "SOC Cases: Kratos AiTM Phishing Kit"
date: 2025-10-15T11:22:30+02:00
draft: false
---

> This post introduces a new blog series called "SOC Cases" where I will try to cover the most prevalent and impactful SOC cases that I face. It is mostly intended to give an insight to fellow SOC Analysts and Engineers.


The Kratos phishing kit is a sophisticated adversary-in-the-middle (AiTM) campaign that abuses trusted services like SendGrid and Amazon S3 to deliver credential-stealing payloads. I came across this Phishing Kit last week and wanted to cover the delivery and data transmission parts quickly. Hence this post dissects the full kill chain, from delivery to exfiltration, with technical artifacts and code snippets.

## Stage 1: Email Delivery via SendGrid

The attack begins with a phishing email sent from:

- **Sender domain**: `*@shop.ploom.ae`
- **Sender IP**: `159.183.75.229`

The email contains a SendGrid-tracked link in this format:

```bash
hxxps[://]u45668289[.]ct[.]sendgrid[.]net/ls/click?upn=upn=u001.0f9jVFLktRMg8paW8jzOIC078BZdDQAY5AOa5upkfntTXMkPp-2Fn3yGRRRQH6TlfU8FQQ48O2EkspxUTHhIwXqeOhCkdK-2Biw0fRMkNKgnu9SUo8M-2B2-2Bo7Ibk4V5aX0bty1NlGhP-2BasLlMzkbu2W2pZOxu8vYw76RnAFZ4MyCg74BUjoUX02x6625GVVyfENnt4KVi_Yp4ydSxZWNatis3HtI6bBnGr2OInsuO841Iacmb4QvkHQ7hbrS36MGYOPCj3GAUI3yyNhrdI9tSqTbY58WPZo4nd3SYI-2Be7GHSqQLJYDbygGlnf3CUlGbpP3E-2F2ZiPR4r84ww7Fvd8zS50ntagHtsBqp-2FruYo-2BPL-2FriC2m9KFcdMqi6pBFI...
```

This link is trusted by many security tools and often bypasses web proxies. When clicked, it sends a POST request to SendGrid, which responds with a **302 redirect** to an Amazon S3 bucket.

## Stage 2: Redirect to Amazon S3 Bucket

The SendGrid redirect leads to a 302 response with following URL redirect:

```bash
hxxp[://]my-redirect-bucket-unique-786797892057439875320823523357594[.]s3-website[.]us-east-2[.]amazonaws[.]com#VICTIM@DOMAIN.TLD
```

As we can see, the fragment `#VICTIM@DOMAIN.TLD` contains the victim's email, indicating a spearphishing campaign. The response also includes an **X-Robots-Tag** to prevent search-engines from indexing the page in order to stay hidden.
Upon inspecting this URL using CURL, I got a 301 Response leading to another moved domain:

```bash
hxxps[://]makominingcorp[.]company
```

This site hosts the final phishing page, designed after a Microsoft 365 Login page. The site itself hosts a modified Cloudflare Turnstile script.
The malicious turnstile script preloads the fragmented victims email adress from the previous webrequests into the forms to make it look more legitimate to the user. 

```javascript
var hashParam = window.location.hash ? window.location.hash.substring(1) : '';
if (/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(hashParam)) {
  var b64 = window.btoa(unescape(encodeURIComponent(hashParam)));
  appendInput(form, 't', b64);
}
```

Furthermore, the script tracks the users behavious such as mouse clicks, keyboard input and form interaction and sends those data to an external Amazon VPS. 

```javascript
document.addEventListener('mousemove', () => userActivity++);
document.addEventListener('keydown', () => inputEvents++);
document.addEventListener('click', () => {
  navigationTimes.push(Date.now());
  if (navigationTimes.length > 10) navigationTimes.shift();
});

appendInput(form, 'analytics_data', JSON.stringify({
  userEngagement: userActivity,
  inputMetrics: inputEvents,
  sessionTime: Date.now() - sessionStart,
  qualityScore: qualityMetrics
}));
form.submit();
```

This behaviour is legitimate cloudflare turnstile behaviour but once the victim submits the form, credentials, session tokens, and potentially 2FA tokens are exfiltrated to an attacker-controlled Amazon VPS

## Indicators of Compromise (IoC)

| **Type**         | **Value**                                                                 |
|------------------|---------------------------------------------------------------------------|
| Redirect URL     | `hxxp[://]my-redirect-bucket-...s3-website.us-east-2.amazonaws.com`         |
| Final Phishing   | `hxxps[://]makominingcorp.company/`                                         |
| Sender Domain    | `shop.ploom.ae`                                                           |
| IPs              | `159.183.75.229`, `172.67.190.19`, `3.5.129.127`                           |


## Conclusions & Learnings

Make sure to:

- Block listed IoCs at perimeter and endpoint levels
- Monitor SendGrid links with unusual redirect behavior
- Inspect URL fragments for embedded PII
- Use browser isolation for email link clicks
- Educate users on AiTM phishing tactics
