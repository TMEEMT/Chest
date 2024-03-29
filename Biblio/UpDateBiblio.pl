#!/usr/bin/perl
use strict;
use warnings;
use File::Copy;

# chmod 755 UpDateBiblio.pl to make it executable
# Use simply with ./UpDateBiblio.pl

### SITE DEPENDENT CONSTANT !!!
my $Global_bib_file = "../GlobalBiblioFile/Global.bib";
my $Local_bib_file = "Local-TME-EMT.bib";


my $RefToBeProcessed_txtfile = "RefToBeProcessed.txt";
my $RefToCitation_jsfile = "RefToCitation.js";
my $RefToAuthorYear_jsfile = "RefToAuthorYear.js";
my $RefToYear_jsfile = "RefToYear.js";
my $RefToTitle_jsfile = "RefToTitle.js";
my $RefToRefs_jsfile = "RefToRefs.js";
my $RefToURL_jsfile = "RefToURL.js";
my $ExceptionalRefsfile = "ExceptionalRefs.txt";
my $Biblio_phpfile = "Biblio.html";
#my $Biblio_phpfile = "Biblio.php";
my $biblio_texfile = "biblio.tex";
my $biblio_texfile_nosuffix = "biblio"; # bibtex needs that!! 
my $biblio_bblfile = "biblio.bbl";
my $bibheaderfile = "bibfileheader.txt";
my $bibfooterfile = "bibfilefooter.txt";
my $booklet_texfile = "booklet.tex";
my $booklet_texfile_nosuffix = "booklet"; # bibtex needs that!! 

###################################################################
###################################################################
## Comment cela marche ?
## [A] On lit tous les fichiers du repertoire Articles/ 
## dont le nom ne commence pas par . mais se termine par .html.
## On cree ainsi le fichier $RefToBeProcessed_txtfile.
## [B] On prend les noms du fichier $RefToBeProcessed_txtfile
## Il s'agit de cles du fichier Local-TME-EMT.bib.
## Le fichier $RefToBeProcessed_txtfile contient une cle par ligne
## ou un commentaire (ligne commencant par #).
## [C] Ensuite, on cree le fichier biblio.tex en omettant les cles 
## qui sont dans $ExceptionalReffile, on le compile et
## on le bibtex.
## [D] On va voir le fichier biblio.bbl
## qui contient les entrees qui nous concerne sauf celles
## qui sont dans $ExceptionalReffile.
## Il faut ensuite construire sept fichiers :
## -- Biblio/RefToCitation.js qui contient une liste dont les
##    elements sont Ref: Facon de le citer
## -- Biblio/RefToAuthor.js qui contient une liste dont les
##    elements sont Ref: Author
## -- Biblio/RefToYear.js qui contient une liste dont les
##    elements sont Ref: Year
## -- Biblio/RefToTitle.js qui contient une liste dont les
##    elements sont Ref: Titre
## -- Biblio/RefToRefs.js qui contient une liste dont les
##    elements sont Ref: Auxiliaries
## -- Biblio/RefToURL.js qui contient une liste dont les
##    elements sont Ref: URL
## -- Biblio/Biblio.html qui sera le fichier affiche.
###################################################################
###################################################################

sub make_RefToBeProcessed_txtfile {
    my ($fhreffile, $fhfile, $dh);
    my @files;
    my ($file, $line, $secondline, $key, $artdir);

    $artdir = "../Articles";
 
    open($fhreffile, ">$RefToBeProcessed_txtfile") #Open file for writing and empty it.
        or die "Cannot open $RefToBeProcessed_txtfile!"; 

    # on recupere tous les articles de suffixe .html sauf ceux dont le nom commencent par .
    opendir($dh, $artdir) || die "Can't opendir $artdir: $!";
    @files = grep { -f "$artdir/$_" } readdir($dh);
    closedir $dh;

    # On scanne tous les articles du repertoire ../Articles
    foreach $file (@files) {
        if($file =~ /^\./){next;}
        if($file !~ /\.html$/){next;}
        if($file eq "Template_Article.html"){next;}
        open($fhfile, "<$artdir/$file") #Open file for reading
            or die "Cannot open $artdir/$file: $!";
        print "Scanning $file for keys ...\n";
        while($line = readline($fhfile)){
            if($line =~ /<script[^>]*>/){
                #print "Candidate ...\n";
                if($line !~ /<\/script[\s]*>/){
                    #entry on two lines
                    chomp($line);
                    $secondline = readline($fhfile);
                    $line = $line.$secondline;
                };
                if($line =~ /<script[^>]*>[\s]*bibref\("([^"]+)"\)[\s]*<\/script[\s]*>/){
                    $key = $1;
                    print $fhreffile $key."\n";
                    print " --> Adding $key from $file\n"
                } else {
                    #print "$file: see $line\n";
                }
            }
        }
        close($fhfile);
    };
    close($fhreffile);
}

sub make_biblio_texfile {
    my $fhfile;
    my $line;
    my $fhreffile;
    open($fhfile, ">$biblio_texfile") #Open file for writing and empty it.
        or die "Cannot open $biblio_texfile: $!"; 

    # Header:
    print $fhfile 
"\\documentclass{article}
\\usepackage{amsfonts}
\\usepackage{amssymb, url, hyperref}
\\usepackage{latexsym}

\\usepackage{authordate1-4}
\\nonstopmode
\\begin{document}
";

    # Adding references:
    open($fhreffile, "<$RefToBeProcessed_txtfile") #Open file for reading
        or die "Cannot open $RefToBeProcessed_txtfile!"; 
    while ($line = readline($fhreffile)){
        chomp($line);
        if($line =~ m/\#/i)
        { #Dont do anything, this is a comment;
        } else {
            print $fhfile "\\nocite{$line}\n";}
    }
    close $fhreffile;

    # Closing file:
    print $fhfile 
"\\bibliographystyle{authordate1}
\\bibliography{Local-TME-EMT}

\\end{document}";

    close $fhfile;
}

sub make_biblio_bblfile {
    #Compiling, bibtexing, compiling, re compiling
    system("latex $biblio_texfile>/dev/null; bibtex $biblio_texfile_nosuffix>/dev/null; latex $biblio_texfile>/dev/null; latex $biblio_texfile>/dev/null");
}

sub format_line{
    my $line = shift;
    $line =~ s/<script[^>]*>[\s]*bibref\("([^"]+)"\)[\s]*<\/script[\s]*>/\\cite\{$1\}/g;
    $line =~ s/<ul>/\\begin\{itemize\}/g;
    $line =~ s/<ul[^>]*>/\\begin\{itemize\}/g;
    $line =~ s/<\/ul>/\\end\{itemize\}/g;
    $line =~ s/<li>/\\item /g;
    $line =~ s/<\/li>/\n/g;
    $line =~ s/<br>/\\par /g;
    $line =~ s/<br\/>/\\par /g;
    $line =~ s/<[^>]*>//g;
    $line =~ s/&([eai])acute;/\\'$1/g;
    $line =~ s/&([eau])grave;/\\`$1/g;
    $line =~ s/&([eaui])circ;/\\^$1/g;
    $line =~ s/&([eaui])uml;/\\"$1/g;
    $line =~ s/&([eau])cedil;/\\c $1/g;
    $line =~ s/&nbsp;/\\,/g;
    return $line;
}

sub make_texfile {
    my ($fhfile, $file, $filename, $fhtexfile);
    my @files;
    my ($line, $artdir, $latexdir, $dh, $title, $key, $secondline);
    $artdir = "../Articles";
    $latexdir = "../Latex";

    # on recupere tous les articles de suffixe .html sauf ceux dont le nom commencent par .
    opendir($dh, $artdir) || die "Can't opendir $artdir: $!";
    @files = grep { -f "$artdir/$_" } readdir($dh);
    closedir $dh;

    # On scanne tous les articles du repertoire ../Articles
    foreach $file (@files) {
        if($file =~ /^\./){next;}
        if($file !~ /\.html$/){next;}
        if($file eq "Template_Article.html"){next;}
        open($fhfile, "<$artdir/$file") #Open $file for reading
            or die "Cannot open $artdir/$file: $!";
	$filename = substr($file, 0, -5) . ".tex";
        print "Adding chapter $filename from $file  ...\n";
	open($fhtexfile, ">$latexdir/$filename") #Open file for writing and empty it.
        or die "Cannot open $latexdir/$filename: $!"; 

        while(($line = readline($fhfile))&&(index($line, "TITLE HERE")==-1)){};
        $title = readline($fhfile);
        chomp($title); 
        print $fhtexfile "\\chapter{".$title."}\n\n";
        print $fhtexfile "Corresponding html file: \\texttt{".$artdir."/".$file."}\n\n";
        while($line = readline($fhfile)){
            ## Section:
            if($line =~ /<div class="section">/){
                readline($fhfile); # <a name="..."></a>
                $title = readline($fhfile);
		chomp($title);
                print $fhtexfile "\\section{".substr($title, 3)."}\n\n";
                readline($fhfile);# </div>
            } elsif($line =~ /<br><span class="THM">([^<]+)<\/span>/){
                ## THM:
                $title = $1;
                print $fhtexfile "\\begin{thm}{".$title."}\n\n";
                readline($fhfile); # <blockquote class="outer-thm">
                readline($fhfile); # <div class="thm">
                while($line = readline($fhfile)){
                    if($line !~ /<\/div><\/blockquote>/){
                        $line = format_line($line);
                        print $fhtexfile $line;
                    } else {
                        print $fhtexfile "\\end{thm}\n\n";
                        last;
                    }}
            } elsif($line =~ /<span class="THM">([^<]+)<\/span>/){
                ## THM:
                $title = $1;
                print $fhtexfile "\\begin{thm}{".$title."}\n\n";
                readline($fhfile); # <blockquote class="outer-thm">
                readline($fhfile); # <div class="thm">
                while($line = readline($fhfile)){
                    if($line !~ /<\/div><\/blockquote>/){ 
                        $line = format_line($line);
                        print $fhtexfile $line;
                    } else {
                        print $fhtexfile "\\end{thm}\n\n";
                        last;
                    }}
            } elsif($line =~ / *Last updated.*/){
                $line = format_line($line);
                print $fhtexfile "\\begin{flushright}\\small\\sl{} " . $line . " \\end{flushright}";
            } else {
                ## Usual entry!
                if(index($line, "<a") > -1){
                    # There is an anchor inside !
                    $line =~ s/<a href="([^"]+)">([^<]*)<\/a>/$2\\footnote{\\url{$1}}/g;
                    $line = format_line($line);
                    print $fhtexfile $line;
                } else {
                    $line = format_line($line);
                    print $fhtexfile $line;}
            }
        }
	close($fhtexfile);
        close($fhfile);
    };
}

sub make_booklet {
    #Compiling, biber-ing, compiling, re compiling
    system("pdflatex $booklet_texfile>/dev/null; biber $booklet_texfile_nosuffix>/dev/null; pdflatex $booklet_texfile>/dev/null; pdflatex $booklet_texfile>/dev/null");
}


sub cure_string {
    my $string_to_cure = shift;

    $string_to_cure =~ s/\{([A-Z]{1})\}/$1/g;
    $string_to_cure =~ s/\{\\em([^\}]*)\}/$1/g;
    $string_to_cure =~ s/\{\\bf([^\}]*)\}/$1/g;
    $string_to_cure =~ s/\\string//g;
    $string_to_cure =~ s/\\url\{([^\}]*)\}/$1/g;

    $string_to_cure =~ s/\\~([a-zA-Z]{1})/&$1tilde;/g;
   # We have to avoid mathematical fields:
    my @fields = split( /\$/, $string_to_cure);
    for(my $nb = 0; $nb <= $#fields; $nb += 2) {
        $fields[$nb] =~ s/{([^}]*)}/$1/g; 
        $fields[$nb] =~ s/~/ /g;}

    my $firstchar = substr($string_to_cure, 0, 1);
    $string_to_cure = join("\$", @fields);
    if( $firstchar eq "\$"){
        if($#fields % 2 == 0){
            $string_to_cure = "\$".$string_to_cure."\$";
        } else {
            $string_to_cure = "\$".$string_to_cure;}
    } else {
        if($#fields % 2 == 1){$string_to_cure .= "\$";}
    }
    # Many more are to be translated!!
    $string_to_cure =~ s/\\&/&amp;/g;
    $string_to_cure =~ s/\\'[c]{1}/&#x107;/g;
    $string_to_cure =~ s/\\'[g]{1}/&#x1F5;/g;
    $string_to_cure =~ s/\\'[G]{1}/&#x1F4;/g;
    $string_to_cure =~ s/\\'[k]{1}/&#x1E31;/g;
    $string_to_cure =~ s/\\'[K]{1}/&#x1E30;/g;
    $string_to_cure =~ s/\\'[n]{1}/&#x144;/g;
    $string_to_cure =~ s/\\'[N]{1}/&#x143;/g;
    $string_to_cure =~ s/\\'[r]{1}/&#x155;/g;
    $string_to_cure =~ s/\\'[R]{1}/&#x154;/g;
    $string_to_cure =~ s/\\'[s]{1}/&#x15B;/g;
    $string_to_cure =~ s/\\'[S]{1}/&#x15A;/g;
    $string_to_cure =~ s/\\'[w]{1}/&#x1E83;/g;
    $string_to_cure =~ s/\\'[W]{1}/&#x1E82;/g;
    $string_to_cure =~ s/\\'[z]{1}/&#x17A;/g;
    $string_to_cure =~ s/\\'[Z]{1}/&#x179;/g;
    $string_to_cure =~ s/\\'([a-zA-Z]{1})/&$1acute;/g;
    $string_to_cure =~ s/\\`([a-zA-Z]{1})/&$1grave;/g;
    $string_to_cure =~ s/\\"([a-zA-Z]{1})/&$1uml;/g;
    $string_to_cure =~ s/\\^([a-zA-Z]{1})/&$1circ;/g;
    $string_to_cure =~ s/\\c ([a-zA-Z]{1})/&$1cedil;/g;
    # End of translation -- hopefully!

    return($string_to_cure);
}

sub trim_string {
    my $string_to_trim = shift;
    
    $string_to_trim =~ s/^\s+//g;
    $string_to_trim =~ s/\.\s*$//g;
    return( $string_to_trim);
}

sub make_RefToAll_jsfile_Biblio_phpfile {
    my $fhfile;
    my ($line, $secondline);
    my ($fhjsfile, $fhbibfile, $fhtitlefile, $fhrefsfile, $fhauthoryearfile, $fhyearfile, $fhurlfile);
    my ($key, $citation_name, $year);
    my ($firstonejs, $firstoneauthoryear, $firstoneyear, $firstonetitle, $firstonerefs);
    my ($bibentry, $authoryear, $title, $refs, $tobetreated, $url);
    my ($fhheaderfile, $fhfooterfile);
    my (%exceptionscitation, %exceptionsauthoryear, %exceptionsyear, %exceptionstitle, %exceptionsrefs);
    my ($fhexceptionsfile);
    my ($nobibentry, $sizeselection, $entrytype, $nbbibentry, $tostudy, $aurl);

    $sizeselection = 5; # Every 5 entries, the background changes; this makes reading easier

    # Build %exceptions and @exceptionalkeys
    open($fhexceptionsfile, "<$ExceptionalRefsfile") #Open file for reading
        or die "Cannot open $ExceptionalRefsfile: $!";
    
    while($line = readline($fhexceptionsfile)){
        chomp($line);
        $key = $line;
        while(($line = readline($fhexceptionsfile))&&($line !~ /^\s*$/)){
            chomp($line);
            if(not exists $exceptionscitation{$key}) {$exceptionscitation{$key} = $line;
            } elsif (not exists $exceptionsauthoryear{$key}) {$exceptionsauthoryear{$key} = $line;
            } elsif (not exists $exceptionsyear{$key}) {$exceptionsyear{$key} = $line;
            } elsif (not exists $exceptionstitle{$key}) {$exceptionstitle{$key} = $line;
            } elsif (not exists $exceptionsrefs{$key}) {$exceptionsrefs{$key} = $line;
            }}}
        
    # Open other files:
    open($fhjsfile, ">$RefToCitation_jsfile") #Open file for writing and empty it.
        or die "Cannot open $RefToCitation_jsfile: $!";
    open($fhauthoryearfile, ">$RefToAuthorYear_jsfile") #Open file for writing and empty it.
        or die "Cannot open $RefToAuthorYear_jsfile: $!";
    open($fhyearfile, ">$RefToYear_jsfile") #Open file for writing and empty it.
        or die "Cannot open $RefToYear_jsfile: $!";
    open($fhtitlefile, ">$RefToTitle_jsfile") #Open file for writing and empty it.
        or die "Cannot open $RefToTitle_jsfile: $!";
    open($fhrefsfile, ">$RefToRefs_jsfile") #Open file for writing and empty it.
        or die "Cannot open $RefToRefs_jsfile: $!";
    open($fhurlfile, ">$RefToURL_jsfile") #Open file for writing and empty it.
        or die "Cannot open $RefToURL_jsfile: $!";
    open($fhbibfile, ">$Biblio_phpfile") #Open file for writing and empty it.
        or die "Cannot open $Biblio_phpfile: $!";
 
    open($fhfile, "<$biblio_bblfile") #Open file for reading
        or die "Cannot open $biblio_bblfile: $!";

    # Header:
    print $fhjsfile "var RefToCitation= {";
    print $fhauthoryearfile "var RefToAuthorYear= {";
    print $fhyearfile "var RefToYear= {";
    print $fhtitlefile "var RefToTitle= {";
    print $fhrefsfile "var RefToRefs= {";
    print $fhurlfile "var RefToURL= {";

    open($fhheaderfile, "<$bibheaderfile") #Open file for reading
        or die "Cannot open $bibheaderfile!";
    while ($line = readline($fhheaderfile)){
        print $fhbibfile $line; 
    }
    close $fhheaderfile;

    # Content:
    $firstonejs = 1; $firstoneauthoryear = 1; $firstoneyear = 1; $firstonetitle = 1; $firstonerefs = 1; 
    $line = readline($fhfile); # \begin{thebibliography}{}
    $line = readline($fhfile); # empty line
    $nobibentry = 0; $nbbibentry = 0; $entrytype = 0; # oddselection 
    print $fhbibfile '<div class="oddselection">';
    while($line = readline($fhfile)){
        chomp($line);
        # if citename doesnt appear, then skip.
        if($line =~ /citename/){
            # Treat the case of beginning on two lines:
            if($line !~ /]/){ #Beg is on two lines
                $secondline = readline($fhfile);
                chomp($secondline);
                $line = $line.$secondline;}
            #separate in two:
            #print $line."\n"; # print on terminal
            #Year can be 1983/84 or 1983/1984
            #Year can be 1983a
            if($line =~ /^\\bibitem\[\\protect\\citename\{(.*)\}(\d{4}[a-z]?(\/\d{2,4})?)]/){
                #We split the checking in two to recognize errors more easily --
                if($line =~ /^\\bibitem\[\\protect\\citename\{(.*)\}(\d{4}[a-z]?(\/\d{2,4})?)\]\{([\*\-\?a-zA-Z01-9]+)\}$/){
                    $key = $4;
                    $citation_name = $1;
                    $year = $2;
                    # There may be difficulties in citation name:
                    $citation_name = cure_string($citation_name);
                    $citation_name = $citation_name.$year;
                    if(exists $exceptionscitation{$key}){
                        $citation_name = $exceptionscitation{$key};}
                    if($firstonejs == 1){
                        print $fhjsfile "\"$key\": \"$citation_name\"";
                        $firstonejs = 0;
                    } else {
                        print $fhjsfile ", \"$key\": \"$citation_name\"";
                    };
                    if(exists $exceptionsyear{$key}){
                        $year = $exceptionsyear{$key};}
                    if($firstoneyear == 1){
                        print $fhyearfile "\"$key\": \"$year\"";
                        $firstoneyear = 0;
                    } else {
                        print $fhyearfile ", \"$key\": \"$year\"";
                    };
                } else {print "Oups in detecting key/year/citation_name\n";};
            } else {print "Oups in detecting key/year\n";};

            # At this level, we have treated the key and the citation names.
            # Remains everyting else :), but for the biblio file.

            $bibentry = "   <li class=\"bibentry\" id=\"$key\"><a name=\"$key\">\n"; # anchor for bibentry
            # Put all the information in one long string:
            $tobetreated = "";
            my $nospace = 0;
            while(($line = readline($fhfile))&&($line !~ /^\s*$/)){
                chomp($line); # print "Yoo!".$line."\n";
                my $last = substr $line,-1,1;
                if($last eq "%"){
                    $line = substr $line,0,-1;
                    $nospace = 1;
                } else { $nospace = 0;}
                if($nospace == 0) {$tobetreated .= " ";}
                $tobetreated .= $line;
            }
            # fields are separated by \newblock
            my @fields = split( /\\newblock /, $tobetreated);
            # print "Oups:".join(" : ", @fields)."\n";
            # Premier champs : nom-annee
            $authoryear = trim_string(cure_string(shift(@fields)));
            if(exists $exceptionsauthoryear{$key}){
                $authoryear = $exceptionsauthoryear{$key};}
            $bibentry .= "     <span class=\"authoryear\" alt=\"$key\">$authoryear</span></a>\n";
            if($firstoneauthoryear == 1){ $firstoneauthoryear = 0;
            } else { print $fhauthoryearfile ",";}
            print $fhauthoryearfile "\"$key\": \"$authoryear\"";
            
            # Second champs : Titre
            if(@fields) {
                $title = trim_string(cure_string(shift(@fields)));
            } else {$title = "";}
            if(exists $exceptionstitle{$key}){
                $title = $exceptionstitle{$key};}
            if($firstonetitle == 1){ $firstonetitle = 0;
            } else { print $fhtitlefile ",";}
            $bibentry .= "<br>\n     &nbsp;&nbsp;&nbsp;<span class=\"title\">$title.</span>\n";
            # In \title, the \ has to be quoted for javascript:
            $title =~ s/\\/\\\\/g;
            print $fhtitlefile "\"$key\": \"$title\"";
            
            # Tout le reste : Refs
            if(@fields) {
		$tostudy = join(" ", @fields);
		# Detect Url:
		if ( $tostudy =~ s/\\url\{(.*?)\}/ / ){
		    $aurl = $1;
		    $aurl =~ s/\\string://;
		} else {$aurl = undef;}
                $refs = cure_string($tostudy);
            } else {$refs = "";}
            if($firstonerefs == 1){ $firstonerefs = 0;
            } else { print $fhrefsfile ",";}
            if(exists $exceptionsrefs{$key}){
                $refs = $exceptionsrefs{$key};}
            print $fhrefsfile "\"$key\": \"$refs\"";
	    if(defined($aurl)){
	        $bibentry .= "  <a href=\"$aurl\">URL</a>";}
            $bibentry .= "     <span class=\"refs\">$refs</span>\n";

            $bibentry .= "   </li>\n"; # end of creation of bibentry
            print $fhbibfile $bibentry;
            $nobibentry += 1;
            $nbbibentry += 1;
            if($nobibentry == $sizeselection){
                $nobibentry = 0;
                print $fhbibfile "</div>\n";
                if($entrytype == 1){
                    print $fhbibfile '<div class="oddselection">';
                } else {
                    print $fhbibfile '<div class="evenselection">';
                }
                $entrytype = 1-$entrytype;}
            }}

    print $fhbibfile '</div>';
    # Closing:
    print $fhbibfile "<br><div class=\"discret\">There are $nbbibentry references.</div>";
    open($fhfooterfile, "<$bibfooterfile") #Open file for reading
        or die "Cannot open $bibfooterfile!";
    while ($line = readline($fhfooterfile)){
        print $fhbibfile $line; 
    }
    close $fhfooterfile;

    print $fhjsfile "};";
    print $fhauthoryearfile "};";
    print $fhyearfile "};";
    print $fhtitlefile "};";
    print $fhrefsfile "};";
    print $fhurlfile "};";

    close $fhfile;
    close $fhjsfile;
    close $fhauthoryearfile;
    close $fhyearfile;
    close $fhtitlefile;
    close $fhrefsfile;
    close $fhurlfile;
    close $fhbibfile;
}
###################################################################
######### Silence ! Maintenant, on travaille ! ####################
###################################################################

print "Copying the new bib-file from $Global_bib_file ...\n";
copy($Global_bib_file, $Local_bib_file) or die "Creation of $Local_bib_file failed: $!";
print("done.\n");

print "Build $RefToBeProcessed_txtfile...\n";
make_RefToBeProcessed_txtfile(); print("done.\n");

print "Build $biblio_texfile from $RefToBeProcessed_txtfile...";
make_biblio_texfile(); print("done.\n");

print "Build $biblio_bblfile from $biblio_texfile...";
make_biblio_bblfile(); print("done.\n");

print "Build $RefToCitation_jsfile, $RefToTitle_jsfile, $RefToRefs_jsfile, $RefToURL_jsfile and $Biblio_phpfile from $biblio_bblfile...";
make_RefToAll_jsfile_Biblio_phpfile(); print("done.\n");

make_texfile();

print "Copying Local-TME-EMT.bib to ../Latex directory\n";
copy($Local_bib_file, "../Latex/Local-TME-EMT.bib") or die "Copy failed: $!";

chdir("../Latex");
print "Entering ../Latex directory\n";
print "Compile $booklet_texfile (can be long due to biber!)...";
make_booklet(); print("done.\n");

chdir("../Biblio");
print "Back to ../Biblio directory\n";

#######################################
### End on the UpDateBiblio.pl script.
#######################################
