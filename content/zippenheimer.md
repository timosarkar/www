+++
title = "Zippenheimer"
date = 2025-01-15T16:59:29+01:00
+++

During some of my doom scrolling on youtube, I have found a guy flexing his new **1 trillion zettabyte** zipbomb. First, I was blown away how he managed to fit 1 trillion zettabytes of data into a 122 kilobytes sized zipfile. He states, that he used a recursive nested approach where you start with lets say, 1 gigabyte of base data which you then compress into a zipfile with a very high compression ratio (likely >95%). Then you create n amount of layers where each layer contains an n amount of recursively zipped base data. Since you compress the files using a very high compression ratio, you can fit **a lot of data** into a zipfile. **And I mean really a lot!**

![bomb](/bomb.jpg)

If you are not familiar with the term "zettabyte", you can find here a table of unit conversions:

```
1 megabyte = 1024 bytes
1 gigabyte = 1024 megabytes
1 terabyte = 1024 gigabytes
1 petabyte = 1024 terabytes
1 exabyte = 1024 petabytes
1 zettabyte = 1024 exabytes
1 yottabyte = 1024 zettabytes
1 ronnabyte = 1024 yottabytes
1 quetta/brontobyte = 1024 ronnabytes
1 geopbyte = 1024 quetta/brontobytes
1 saganbyte = 1024 geopbytes
```

All units until yottabytes are officially standardized. The others are possible, but widely used/seen candidates for standardization. **For reference:** yearly internet traffic is estimated at **3.3 zettabytes**.

## Dangers of a Zipbomb

You might ask yourself, why people waste their time to create zipfiles with astronomically large expansion sizes? Well, nowadays these files wouldn't necessarily pose a threat. But if you are using a **ZIP Extractor** which recursively extract nested zipfiles, this is a threat for you. Since an extractor must handle huge expansion sizes that exponentially grow at each level/depth, the extractor will eventually crash and cause your computer os to freeze. I am also pretty sure, that Windows 7 and XP have recursive extraction builtin. If not you might test using **ExtractNow**.

## Record Holders

On 13th of November 2020 somebody made a zipbomb that expands to **55.4 yottabyte**. Recently (13th of May 2024) an user named **NIMDAFreaky** published a zipbomb on discord, sized at **1,148 saganbytes**. However, two weeks ago somebody nicknamed, **TheCanadianKid** created a zipbomb with **41,400,223,250 saganbytes**. His compressed file was sized roughly **7 gigabytes**. 

Damn. This must be the largest ever created. Right? I do not think so. **I might be able to create a much larger one...**

## Creating my own

I quickly wrote a **golang** program. The program is called tsarbomba and was recently open-sourced on [GitHub](https://github.com/timosarkar/tsarbomba). The program creates a **1 megabyte needle file** which is intended as the base file. The file is filled with repetitive "0"s. The needle file is then compressed into an archive called **level1.zip**. The compression-ratio for the first levels are always at roughly 99.99%. So therefore, the archive would shrink from 1 megabyte to 1 kilobyte. The program then enters an iterative loop for which in every iteration, it will create a new archive with 10 copies of the previous archive. So **level2.zip** would contain 10 level1.zip files. You can see, that the real size will unproportionally stay relative to the decompressed expansion size which grows exponentially to astronomic values. 

I have also added thread-safe **goroutines** and **channels** to speed the programs runtime up by some orders of magnitude. Then I did a test run with 70 layers where each layer contains 10 archives of the previous level. After roughly 90 seconds, I was left with a **21 gigabyte** large zipbomb (real compressed filesystem size). The decompressed expansion size was around **10,000,000,000,000,000,000,000,000 saganbytes**. 

And this value is much larger than the previous record holder. **I therefore claim my bomb to be the worlds largest zipbomb ever made. Muahahaha.**

>Note: I have not uploaded the final zipbomb to github, as it has a hard-limit of 2 gigabytes. Even for git LFS. I am currently **sharding** the tsarbomba archive into 2 GB shards so I can upload it for verification.

## Size comparison

For the final decompressed expansion size of tsarbomba: If every byte was a **grain of sand**. The total volume and size of the zipbomb would be **100 times larger than the total volume of our milky-ways galaxy**. Let that sink in!