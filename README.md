# LJFindEmbeds
A tool for finding all the LJ posts in a journal with media embeds in them.  Its only programmatic dependency is wget. It builds a navigable local cache on disk of all a LJ journal's posts that have media embeds in them, and writes an index file.

## What this is for
The Dreamwidth Importer imports journals from Livejournal.  It does this reasonably well, but one thing it glitches on is importing a LJ entry (post) that has a media embed in it, such as a YouTube video.  The problem is with LJ.  The way LJ handles media embeds is apparently to store the embed HTML separately from the post.  While the Livejournal site necessarily serves up the raw HTML of the embed, er, embeded in the webpage on the LJ website when being served the ordinary way so it can render in the browser, the XML output of the LJ Exporter only includes the pointers to these snippets of HTML.  The LJ Exporter – the official programmatic interface to LJ – is what Dreamwidth interoperates with.  Thus the copy of the post available to the Dreamwidth Importer only has a cryptic pointer a la "lj-embed id=XYZ", and has no access to whatever it was that was originally embedded.  Neither does anything else that uses the LJ Exporter.

This script is to assist in the <strong>manual updating of one's Dreamwidth journal, after importing a Livejournal journal, to fix the media embeds.</strong>

## How this helps (What this does)
This script identifies all the journal entries in the specified journal that have media embeds in them, and downloads local copies of all those posts into a directory called "<i>username</i>.livejournal.com". It then generates an index.html that presents conveniently paired links: the link to the cached LJ file (by post title) and the link to the corresponding day in your DW journal; it also lists the corresponding original URL to the post on Livejournal.

## Requirements
  *  perl (tested against v5.10.1)
  *  wget (tested against v1.12)
  *  a cookie file that wget can read ("Netscape-style") that has your authenticated LJ cookies (instructions below.)

## Usage

0) Make a directory in which your want your results to go.  cd into it.

1) Download this script; put it someplace convenient, like into your results directory; and make it executable (<code>chmod u+x ljFindEmbeds.pl</code>).

2) Come up with your cookie file (instructions below).  Put it somewhere you can find it, like in your results directory.

3) In your directory for the archive, invoke the script: <code>./ljFindEmbeds.pl -u usernameonlj/usernameondw -s yyyy-mm -c path/to/authenticatedcookies.txt</code> where:

   * -u is a LJ username, or an LJ/DW username pair (if you have a different username on the two services), 
   *  -s is the starting month and year of your journal, expressed yyyy-mm, and 
   * -c is your cookie file with your authenticated LJ and DW cookies. 

The arguments are all required.

4) After it has completed, open a web browser.  Use the File Open method to open your new directory; you will get a directory listing with a bunch of stuff in it.  Click on index.html to get your convenient report.

## Making a Cookie File

The most efficient way I know to make a wget-compatible cookie file is to use a browser add-on for the job.  I'm partial to the <a href="https://addons.mozilla.org/en-US/firefox/addon/export-cookies/?src=userprofile">"Export Cookies" add-on to Firefox</a>, and mdlbear at dreamwidth recommends the <a href="https://chrome.google.com/webstore/detail/cookietxt-export/lopabhfecdfhgogdbojmaicoicjekelh?hl=en">"cookie.txt export" add-on for Chrome</a>.  Once you have your browser with the appropriate add-on installed, you can log in to LJ as usual – it's okay if the LJ ToS pop-up is there, just ignore it and don't click anything in the window – and once logged in, use the add-on to export the cookies (in Firefox, the Tools menu &gt; "Export Cookies..." to save them to a file; in Chrome, click the toolbar button and the cut-and-paste the cookies into a text file).

