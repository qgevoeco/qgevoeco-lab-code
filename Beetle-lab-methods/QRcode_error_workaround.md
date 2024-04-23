---
title: "QR code montage error workaround"
---

## The Problem
Occasionally there is an issue with ImageMagick (specifically version 6) generating the pdf of QR codes. This is linked to a ghostscript (`gs`) version. These issues cause the pdf to not be made correctly in the step invoking the `montage` command at the end of "QRcode.sh".

## The Workaround
Getting around this requires disabling the ghostscript formatting types in ImageMagick's policies. Using `sudo` find the _policy.xml_ file for ImageMagick and comment out the ghostscript formatting section.

I have done this using `sudo nano /etc/ImageMagick-6/policy.xml` then commenting out this section at the bottom:

```
  <!-- disable ghostscript format types -->
   <policy domain="coder" rights="none" pattern="PS" />
   <policy domain="coder" rights="none" pattern="PS2" />
   <policy domain="coder" rights="none" pattern="PS3" />
   <policy domain="coder" rights="none" pattern="EPS" />
   <policy domain="coder" rights="none" pattern="PDF" />
   <policy domain="coder" rights="none" pattern="XPS" />
```

with a html comment such as:

```
  <!-- disable ghostscript format types -->
<!-- MEW: commenting out as workaround for montage code on XX date
   <policy domain="coder" rights="none" pattern="PS" />
   <policy domain="coder" rights="none" pattern="PS2" />
   <policy domain="coder" rights="none" pattern="PS3" />
   <policy domain="coder" rights="none" pattern="EPS" />
   <policy domain="coder" rights="none" pattern="PDF" />
   <policy domain="coder" rights="none" pattern="XPS" />
END commenting out for workaround -->
```
