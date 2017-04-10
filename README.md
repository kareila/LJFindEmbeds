# LJFindEmbeds
A tool for finding all the LJ posts in a journal with media embeds in them.  Its only programmatic dependency is wget. It builds a navigable local cache on disk of all a LJ journal's posts that have media embeds in them, and writes an index file.

## What this is for
The Dreamwidth Importer imports journals from Livejournal reasonably well.  But one glitch it has is when an entry (post) has a media embed in it, such as a YouTube video.  The way LJ handles that is apparently to store the embed HTML separately; while it necessarily serves up the raw HTML on the LJ website, the LJ Exporter only includes the pointers to these snippets of HTML.  Thus the Dreamwidth Importer has no access to whatever it was that was embedded, and neither does anything else that uses the LJ Exporter.

This script is to assist in the <strong>manual updating of one's Dreamwidth journal, after importing a Livejournal journal.</strong>

## How this helps (What this does)
This script downloads identifies all the journal entries in the specified journal that have media embeds in them, and downloads local copies of them into a directory called "username.livejournal.com". It then generates an index.html that presents you with conveniently paired links: the link to the cached LJ file (by post title) and the link to the corresponding day in your DW journal.

## Requirements
• perl (tested against v5.10.1)<br />
• wget (tested against v1.12)<br />
• a cookie file that wget can read ("Netscape-style") that has your authenticated LJ <em>and</em> DW cookies (instructions below.)

## Usage

0) Make a directory in which your want your results to go.  cd into it.

1) Download this script; put it someplace convenient, like into your results directory; and make it executable (<code>chmod u+x ljFindEmbeds.pl</code>).

2) Come up with your cookie file (instructions below).  Put it somewhere you can find it, like in your archive directory.

3) In your directory for the archive, invoke the script: <code>./ljFindEmbeds.pl -u usernameonlj/usernameondw -s yyyy-mm -c path/to/authenticatedcookies.txt</code> where:

• -u is a LJ username, or an LJ/DW username pair (if you have a different username on the two services),
• -s is the starting month and year of your journal, expressed yyyy-mm, and
• -c is your cookie file with your authenticated LJ and DW cookies.

The arguments are all required.

4) After it has completed, open a web browser.  Use the File Open method to open your new directory; you will get a directory listing with a bunch of stuff in it.  Click on index.html to get your convenient report.

## Making a Cookie File

The most efficient way I know to make a wget-compatible cookie file is to use a browser add-on for the job.  I'm partial to the <a href="https://addons.mozilla.org/en-US/firefox/addon/export-cookies/?src=userprofile">"Export Cookies" add-on to Firefox</a>, and mdlbear at dreamwidth recommends the <a href="https://chrome.google.com/webstore/detail/cookietxt-export/lopabhfecdfhgogdbojmaicoicjekelh?hl=en">"cookie.txt export" add-on for Chrome</a>.  Once you have your browser with the appropriate add-on installed, you can log in to Dreamwidth and LJ as usual – it's okay if the LJ ToS pop-up is there, just ignore it and don't click anything in the window – and once logged in to both, use the add-on to export the cookies (in Firefox, the Tools menu &gt; "Export Cookies..." to save them to a file; in Chrome, click the toolbar button and the cut-and-paste the cookies into a text file).

