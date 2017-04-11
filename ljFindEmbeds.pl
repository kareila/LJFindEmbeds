#!/usr/bin/perl
use strict; 

# called ljfindEmbeds.pl -username usernameonlj/usernameondw -startdate yyyy_mm -cookiefile path/to/authenticatedcookiefile.txt


# Must take first month/year as argument; 
# also, we could figure out who you are, but why don't you just tell us
my $authenticatedcookies = "";
my $startyear = "";
my $startmonth = "";
my $user ="";
my $dwsubdomain = "";

sub arguer {
	my $nextarg = "";
	my $usernames = "";
	my $startdate = "";
	for my $arg (@ARGV) {
		if ($nextarg eq "usernames") {
			$usernames = $arg;
		} elsif ($nextarg eq "startdate") {
			$startdate = $arg;
		} elsif ($nextarg eq "authenticatedcookies") {
			$authenticatedcookies = $arg;
		}
		$nextarg = "";
		
		if ($arg =~ /^\-u(|user(|name)(|s))/ ) {
			$nextarg = "usernames";
		} elsif ($arg =~ /^\-s(|tart(|date))$/ ) {
			$nextarg = "startdate";
		} elsif ($arg =~ /^\-(|auth(|enticated))c(|ookies)$/ ) {
			$nextarg = "authenticatedcookies";		
		}
	}
	($user, $dwsubdomain) = split /\//, $usernames if $usernames;
	($user) or die "No LJ user specified. \n";
	if (! ($dwsubdomain) ) { $dwsubdomain = $user; }
	$dwsubdomain =~ s/\_/\-/g;
	if ($startdate =~ /(\d{4})(\_|\-|\/)(\d{2})/) {
		$startyear = $1;
		$startmonth = $3;
	} elsif ($startdate) {
		die "Couldn't parse the startdate argument, $startdate.\n";
	}
	($startyear, $startmonth) = split /\_|\-|\//, $startdate if $startdate;
	die "No start date given!\n" unless $startyear && $startmonth;
	($authenticatedcookies) or die "No authenticated cookie file specifed.  Can\'t access the LJ exporter without logging in, sorry.\n";
	(-f $authenticatedcookies) or die "Can\'t find authenticated cookie file \"$authenticatedcookies\".\n";

}
arguer;

sub main {
	my $embedreport = find_all_embed_posts();
	$embedreport=add_lj_urls_to_embed_report($embedreport);
	my $urllist = make_urllist_of_embed_post($embedreport);
	open (URLLIST, ">", "urllist.txt") or die "Couldn't write the URL list to urllist.txt, so here it is: \n $urllist\n";
	print URLLIST $urllist;
	close URLLIST;
	print "Fetching all journal posts with embeds.  This could take a while..."; 
	wget_all_posts_with_embeds('urllist.txt');
	print "done.\n"; 

	unlink $urllist;
	my $subdomain = $user;
	$subdomain =~ s/\_/\-/g;
	pruneOutToS("$subdomain".'.livejournal.com');
	print "Making index.html file.\n";
	make_index("$subdomain".'.livejournal.com', $embedreport);
	###
	# print $urllist;
}
main();

# wget the export page
sub wget_export_a_month {
	#takes yyyy mm, requires global $user
	#returns the XML export for that year-month as a string
	my $yyyy=$_[0];
	my $mm=$_[1];
	#returns the webpage for that folder as a string
	my $url  = "http://www.livejournal.com/export_do.bml?authas=$user" ;
	my $postdata = 'what=journal&year='.$yyyy.'&month='.$mm.'&format=xml&header=checked&encid=2&field_itemid=checked&field_eventtime=checked&field_logtime=checked&field_subject=checked&field_event=checked&field_security=checked&field_allowmask=checked&field_currents&submit=Proceed';
	

	my $commandstring = "wget -q --cookies=on --keep-session-cookies --save-cookies cookiejar.txt --load-cookies $authenticatedcookies --header \"X-LJ-Auth: cookie\"  --post-data \'$postdata\' -O - \'$url\'"; #WORKS!
	
#	print $commandstring."\n";
	return `$commandstring `;
} #takes yyyy mm, returns the XML export for that year-month as a string

sub TEST_wget_export_a_month {
	my $page = "";
	$page = wget_export_a_month($startyear,$startmonth);
	print $page;
}
#TEST_wget_export_a_month;

# The right way to do this is to use a proper XML parser.  We're so not going to do that.

# we want the "eventtime" xml field!
sub find_the_embeds_posts_one_month {
# takes an XML month-of-posts export
# returns a string w each line formatted yyyy/mm/dd\tposttitle\n

	my $results="";
	my $eventtime="";
	my $subject="";
	for my $line (split /^/, $_[0]) {
		if ($line =~ /^<eventtime>(\d{4}-\d{2}-\d{2}) /) {
			$eventtime = $1;
			$eventtime =~ s/\-/\//g;
			$subject = "";
		} elsif ($line =~ /^<subject>(.*)<\/subject>$/) {
			$subject = deescape_subject($1);
		} elsif ($line =~ /\&lt;lj-embed id=\&quot;\d*\&quot;\/\&gt;/) {
			$results .= $eventtime . "\t" . $subject ."\n";
		}
	}
		
	return $results; #WORKS!

} # takes an XML month-of-posts export;returns a string w each line formatted yyyy/mm/dd\tposttitle\n

sub TEST_find_the_embeds_posts_one_month {
	my $page = "";
	$page = wget_export_a_month($startyear,$startmonth);
	print find_the_embeds_posts_one_month($page);
}
#TEST_find_the_embeds_posts_one_month;

# Loop over all months and years from the start, compiling one great variable of the hits

sub find_all_embed_posts {
# takes nothing but requires globals $startyear and $startmonth
# returns report of all posts with embeds, formated one per line: yyyy/mm/dd\tsub\n

	my $accumulator="";
	my $thisyear = `date +%Y`;
	chomp($thisyear);
	my $thismonth = `date +%m`;
	chomp($thismonth);
	my $page;
	
	print "Fetching exports to check for embeds.\nStarting: $startyear\-$startmonth; Ending: $thisyear\-$thismonth.\n";
	
#	$startmonth =~ s/^0+//;
	my $m;
	my $y;
	my $embedsfound=0;
	my $totalembeds=0;
	my $results="";

	for (my $m = $startmonth; $m < 13 ; $m++) {
		$embedsfound = 0;
		print "Fetching export $startyear\-$m...";
		$page = wget_export_a_month($startyear,$m);
		print "checking for embeds...";
		$results = find_the_embeds_posts_one_month($page);
		$accumulator .= $results;
		$embedsfound = scalar(split(/^/, $results));
		print "done. Found $embedsfound embeds.\n";
		$totalembeds += $embedsfound;
	}
	for (my $y = 1+$startyear ; $y < $thisyear; $y++) {
		for (my $m = 1; $m < 13 ; $m++) {
			print "Fetching export $y\-$m...";
			$page = wget_export_a_month($y,$m);
			print "checking for embeds...";
			$results = find_the_embeds_posts_one_month($page);	
			$accumulator .= $results;
			$embedsfound = scalar(split(/^/, $results));
			print "done. Found $embedsfound embeds.\n";
			$totalembeds += $embedsfound;
		}
	}
	for (my $m = 1; $m <= $thismonth ; $m++) {
		print "Fetching export $thisyear\-$m...";
		$page = wget_export_a_month($thisyear,$m);
		print "checking for embeds...";
		$results = find_the_embeds_posts_one_month($page);
		$accumulator .= $results;
		$embedsfound = scalar(split(/^/, $results));
		print "done. Found $embedsfound embeds.\n";
		$totalembeds += $embedsfound;
	}
	print "Total embeds found: $totalembeds.\n";
	return $accumulator; #WORKS	?
} # takes nothing but requires globals $startyear and $startmonth; returns report of all posts with embeds, formated one per line: yyyy/mm/dd\tsub\n

sub TEST_find_all_embed_posts {
	print find_all_embed_posts;
}
#TEST_find_all_embed_posts;

# loop over embed post report, add LJ urls.
sub add_lj_urls_to_embed_report {
# takes an embed report (two field) as a string
# returns a three-field embed report
	my $embedreport="";
	my %monthsvids;
	my $ym="";
	my $subj="";
	# first, make a hash where the keys are yyyy-mm strings for each month that is represented in the embed report
	for my $line (split /^/, $_[0]) {
		($ym,$subj) = split /\t/, $line;
		my @ymd = split /\//, $ym;
		$monthsvids{ $ymd[0]."-".$ymd[1] } = "";
	}
	# next, go get those pages from the user's LJ "calendar"/"archive", and
	# stow them as strings in the hash.
	for my $ym (keys %monthsvids) {
		my $y;
		my $m;
		($y, $m) = split /\-/, $ym;
		$monthsvids{$ym} = wget_LJ_one_month($y,$m);
	}
	# Now we have a yyyy-mm keyed hash of the relevant webpages
	# (this may be terrible for memory for big journals - consider 
	# caching to disk?
	
	# Now loop over the embed report
	for my $line (split /^/, $_[0]) {
		chomp $line;
#		print "Line: $line ...";
		($ym,$subj) = split /\t/, $line;
		my @ymd = split /\//, $ym;
#		print "extracting URL in $ymd[0]/$ymd[1] ...";
		my $url = extract_corresponding_url(
			$subj, 
			$monthsvids{ $ymd[0]."-".$ymd[1] } 
			);
#		print "done: $url.\n";
		$embedreport .= $line . "\t" . $url . "\n";
	}
	return $embedreport;
}

sub TEST_add_lj_urls_to_embed_report {
	my $embedreport = find_all_embed_posts;
	print add_lj_urls_to_embed_report($embedreport);
}
#TEST_add_lj_urls_to_embed_report;

# return the LJ page for one month
sub wget_LJ_one_month {
# takes yyyy mm
# returns an LJ page as a string
	
	my $yyyy=$_[0];
	my $mm=$_[1];
	#returns the webpage for that folder as a string
	$user =~ s/\_/\-/g;
	my $url  = "http://$user.livejournal.com/$yyyy/$mm" ;
	print "Fetching page: $url\n";

	my $commandstring = "wget -q --cookies=on --keep-session-cookies --save-cookies cookiejar.txt --load-cookies $authenticatedcookies --header \"X-LJ-Auth: cookie\"  -O - \'$url\'"; 
	
#	print $commandstring."\n";
	return `$commandstring `; # works?
}

sub TEST_wget_LJ_one_month {
	print wget_LJ_one_month($startyear,$startmonth);
}
#TEST_wget_LJ_one_month;

sub extract_corresponding_url {
# takes subj and page, requires global $user
# returns a URL.  Inshallah.
	my $subj = $_[0];
	my $page = $_[1];
	chomp $subj;
	# Who knows what sort of exciting characters are in that subject string?
	$subj = quotemeta $subj; 
	# usernames can have "_"s in them, but they're coverted to "-"s by LJ
	# in URLs.
	$user =~ s/\_/\-/g;
	for my $line (split /^/, $page) {
		# I know we're not supposed to parse HTML with regexes.
		# I am going to perl hell.
		if ($line =~ /<a href\=('|")(http:\/\/$user\.livejournal\.com\/\d*\.html)('|")>\s*$subj\s*<\/a>/) {
			return $2;	
		} # note this regex will fail if there's any other attributes in the A 
		# tag of the link.  Sorry, there's not much to be done about that, 
		# except individual users can try to tweek the regex to match their
		# personal LJ style.  The perils of screenscraping a user-skinable site.
	}
}

sub TEST_extract_corresponding_url {
	my $testHTML =  wget_LJ_one_month('2017','01');
	print extract_corresponding_url('[music, pols] Fwd: &quot;(I Can&apos;t Keep) Quiet&quot;',$testHTML);
}
#TEST_extract_corresponding_url;

sub deescape_subject{
#takes a subject line as a string
#returns a string

	my $subject = $_[0];
	# LJ's export substitutes HTML entities for some characters.  It does not
	# do this in serving journal pages, so the subjects lines in the export 
	# will not match the subject lines on LJ, if they contain these characters.
	# So we have to convert them back.  The two I know about are:
	# &apos; for ' and &quot; for ".
	$subject =~ s/\&apos;/\'/g;
	$subject =~ s/\&quot;/\"/g;
	return $subject;
} #takes a subject line as a string, returns a string

sub make_urllist_of_embed_post {
# takes a three-column embedreport as a string,
# returns a one-column multi-line string, with one URL to a line.
	my $results="";
	my @fields;
	for my $line (split /^/, $_[0]) {
		(@fields) = split /\t/, $line;
		$results .= $fields[2];
	}
	return $results; #WORKS!
} # takes a three-column embedreport as a string; returns a one-column multi-line string, with one URL to a line.

sub wget_all_posts_with_embeds{
# takes a filename of the urllist as a string
# runs the wget, writing the files to disk
	my $urlfile = $_[0];

	my $commandstring = "wget -q --cookies=on --keep-session-cookies --save-cookies cookiejar.txt --load-cookies $authenticatedcookies --header \"X-LJ-Auth: cookie\"  -x -i $urlfile"; 
	
#	print $commandstring."\n";
	return `$commandstring `; # works?

	
}

sub pruneOutToS{
# takes a directory name as a string (expect something.livejournal.com)
# edits all the files in it for the ToS crap.
	my $dir = $_[0];
	#for every html file in cur dir
	my @files = <$dir/*.html>;
	for my $journalfile (@files) {
		print "DeToSing $journalfile...\n";
		open (JOURNALFILE, "<", "$journalfile");
		my $accumulator ="";
		my $skip=0;
		my $div_countdown = 0;
#		my $now=`date`;
		my $rutos_start = '<div class="flatblue rutos">';
		$rutos_start = quotemeta $rutos_start;
		my $rutos_end = 'data-rutos-elem="submit"';
		$rutos_end = quotemeta $rutos_end;
		while (my $line = <JOURNALFILE>) {
			if ($line =~ /$rutos_start/ ) {
				$skip = 1;
				next;
			} elsif ($line =~ /^\s*b-fader\S*$/) {
				next;
			} elsif ($skip == 1) {
				if ($line =~ /$rutos_end/) {
					$div_countdown = 5;
					next;
				}
				if ( $div_countdown > 0 ) {
					if ($line =~ /<\/div>/) {
						$div_countdown--;
						if ($div_countdown == 0) {
							$skip = 0;
						}
						next;
					}
				}
				next;
			}
			$accumulator .= $line;
		}
		close JOURNALFILE;
		open (JOURNALFILE, ">", "$journalfile");
		print JOURNALFILE $accumulator;
		close JOURNALFILE;
	}

} # takes a directory name as a string (expect something.livejournal.com), edits all the files in it for the ToS crap.

sub TEST_pruneOutToS {
	pruneOutToS( "$user".'.livejournal.com' );
}
#TEST_pruneOutToS;

sub make_index {
# takes the directory as a string and the three-column embed report as a multiline string
# writes an index.html file to disk in the subdomain.livejournal.com dir
	my $dir = $_[0];
	my $embedreport = $_[1];
	my @record;
	my $ymd;
	my @url;
	my $filename;
	my $accumulator ="";

	$accumulator .= "<html>\n<head>\n<title>Journal Posts with Embeds - $dir</title>\n</head>\n<body>\n<h1>Journal Posts with Embeds - $dir</h1>\n\n<p>yyyy/mm/dd links to Dreamwidth, subject links to local cache of LJ.</p>\n\n<ul>";

	for my $line (split /^/, $embedreport) {
		chomp $line;
		(@record) = split /\t/, $line;
		$ymd = $record[0];
		(@url) = split /\//, $record[2];
		$filename = pop @url;

		$accumulator .= '<li><a href="https://'.$dwsubdomain.'.dreamwidth.org/'.$ymd.'">'.$ymd.'</a> - <a href="'.$filename.'">'.$record[1].'</a>  ('.$record[2].')</li>'."\n";
	}
	
	$accumulator .= "</ul>\n</body>\n</html>";
	
	print "Writing index.html into directory $dir\n";
	open (INDEX, ">", "$dir".'/index.html') or die "Couldn't write index.html, so here it is:\n $accumulator\n";
	print INDEX $accumulator;
	close INDEX;
}


