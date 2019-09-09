#!/usr/bin/env perl


# Declaration of pragmas
use strict;
use utf8;
use open qw/:std :utf8/;


# Call of external modules
use Encode qw(decode_utf8 encode_utf8 is_utf8);
use Getopt::Long;

# Perl modules specific for this application
use File::Copy;
use Excel::Writer::XLSX;
use Excel::Writer::XLSX::Utility;

# Programme name
my ($programme) = $0 =~ m|^(?:.*/)?(.+)|;
my $substitute  = " " x length($programme);

my $usage = "Usage: \n" . 
            "    $programme -i input_file -e Excel_file [ -f min ] [ -u max ] \n" .
#            "    $programme -i input_file -e Excel_file [ -f min ] [ -u max ] [ -l (fr|en) ] \n" .
#            "    $programme -i input_file -c CSV_file [ -f min ] [ -u max ] [ -l (fr|en) ] \n" .
#            "    $programme -i input_file -t TSV_file [ -f min ] [ -u max ] [ -l (fr|en) ] \n" .
            "    $programme -h\n\n";

my $version     = "0.1.4";
my $changeDate  = "August 7, 2019";

# Initialising global variables 
# necessary for options
my $csv        = undef;
my $excel      = undef;
my $from       = undef;
my $help       = undef;
my $input      = undef;
my $language   = 'en';
my $tsv        = undef;
my $upto       = undef;

eval    {
        $SIG{__WARN__} = sub {usage(1);};
        GetOptions(
                "csv=s"      => \$csv,
                "excel=s"    => \$excel,
                "from=i"     => \$from,
                "help"       => \$help,
                "input=s"    => \$input,
                "language=s" => \$language,
                "tsv=s"      => \$tsv,
                "upto=f"     => \$upto,
                "xcel=s"     => \$excel,
                );
        };
$SIG{__WARN__} = sub {warn $_[0];};

if ( $help ) {
        print "\nProgramme: \n";
        print "    “$programme”, version $version ($changeDate)\n";
        print "    Generates an Excel file from a “doc × term” file and list terms in \n";
        print "    descending number. It is possible to specify the minimum and maximum \n";
        print "    numbers of occurrences for a term. Terms outside these limits are \n";
        print "    checked. \n";
        print "    The generated Excel file is used to indicate which terms are to be \n";
        print "    deleted or replaced from the “doc × term” file before applying a \n";
        print "    clustering analysis. \n";
#        print "     \n";
        print "\n";
        print $usage;
        print "\nOptions: \n";
#        print "    -c  specify the name of the CSV output file \n";
        print "    -e  specify the name of the output Excel file \n";
        print "    -f  specify the minimum number of documents in which a term can be found \n";
        print "    -h  display this help and exit \n";
        print "    -i  specify the name of the raw “doc × term” input file  \n";
#        print "    -l  specify the language used (French or English, English by default) \n";
#        print "    -t  specify the name of the TSV output file \n";
        print "    -u  specify the maximum number of documents in which a term can be found \n";
        print "        (expressed in percentage) \n";

        exit 0;
        }

usage(2) if not $input or not $excel;

$from = 0.0 if not defined $from;
if ( defined $upto ) {
        if ( $upto =~ /,/ ) {
                $upto =~ s/;/./;
                }
        if ( $upto > 100.0 or $upto < 0.0 ) {
                print STDERR "Error: argument of option “-u” is a percentage value between 0.0 and 100.0\n";
                usage(3);
                }
        }
else    {
        $upto = 100.0;
        }

# Global variables
my $nbDocs  = undef;
my $nbTerms = undef;
my $output  = undef;
my $xlsx    = undef;
my %docTerm = ();
my %term    = ();

open(INP, "<:utf8", $input) or die "$!,";
while(<INP>) {
        chomp;
        s/\r//go;       # just in case ...
        my ($doc, $term) = split(/\t/);
        $docTerm{$doc}{$term} ++;
        }
close INP;

foreach my $doc (keys %docTerm) {
        $nbDocs ++;
        foreach my $term (keys %{$docTerm{$doc}}) {
                $term{$term} ++;
                }
        }
foreach my $term (keys %term) {
        $nbTerms ++;
        }

createExcel();


exit 0;


sub usage
{
print STDERR $usage;

exit shift;
}

sub createExcel
{
# On n'utilise pas les couleurs pour l'instant, mais ça viendra !
my %couleur = (
        "LightSalmon"   => [33, 255, 204, 204],
        "PaleGoldenrod" => [13, 238, 232, 170],
        "PaleGreen"     => [12, 152, 251, 152],
        );

# Création d'un nouveau fichier Excel 2010+
my $path = ".";
if ( defined $ENV{'TEMP'} ) {
        $path = $ENV{'TEMP'};
        }

# Gestion des interruptions
$SIG{'HUP'} = 'cleanup';
$SIG{'INT'} = 'cleanup';
$SIG{'QUIT'} = 'cleanup';
$SIG{'TERM'} = 'cleanup';

$output = "$path/temp$$.xlsx";
$xlsx   = Excel::Writer::XLSX->new($output);

# Création de quelques formats
my $format0 = $xlsx->add_format(
                        bold        => 1,
                        size        => 12,
                        );

my $format1 = $xlsx->add_format(
                        text_wrap   => 1,
                        align       => 'center',
                        valign      => 'vcenter',
                        size        => 14,
                        bold        => 1,
                        );

my $format2 = $xlsx->add_format(
                        align       => 'center',
                        );

my $format3 = $xlsx->add_format(
                        bold       => 1,
                        );

my $format4 = $xlsx->add_format(
                        bold       => 1,
                        num_format => '0.0',
                        );

my $format5 = $xlsx->add_format(
                        num_format => '0.0 %',
                        );

# Pour les couleurs quand on en aura besoin
my %format = ();
foreach my $color (keys %couleur) {
        $xlsx->set_custom_color(@{$couleur{$color}});
        $format{$color} = $xlsx->add_format(
                                bg_color => $couleur{$color}->[0],
                                pattern  => 1,
                                );
        }

# Ajout d'une feuille de calcul : les paramètres
my $sheet = $xlsx->add_worksheet('Parameters');

$sheet->set_column(1, 1, 12);
$sheet->set_column(2, 2, 20);
$sheet->set_column(3, 3, 80);

$sheet->write_string(1, 1, "Parameters:", $format0);
$sheet->write_string(3, 2, "Input file");
$sheet->write_string(3, 3, $input, $format3);
$sheet->write_string(4, 2, "Nb. of documents");
$sheet->write_string(4, 3, $nbDocs, $format3);
$sheet->write_string(5, 2, "Nb. of terms");
$sheet->write_string(5, 3, $nbTerms, $format3);
$sheet->write_string(6, 2, "Maximum value");
$sheet->write_string(6, 3, "$upto %", $format4);
$sheet->write_string(7, 2, "Minimum value");
$sheet->write_string(7, 3, $from, $format3);

# Ajout d'une feuille de calcul : les résultats par ordre alphabétique
$sheet = $xlsx->add_worksheet("Term list");


# Définition de cette feuille de calcul comme celle par défaut à l'ouverture
$sheet->activate();

# Réglage de la taille des colonnes et de la première ligne
$sheet->set_column(0, 0, 6);
$sheet->set_column(1, 2, 10);
$sheet->set_column(3, 4, 70);
$sheet->set_row(0, 40, $format1);

$sheet->write_string(0, 0, '?');
$sheet->write_string(0, 1, 'Nb.');
$sheet->write_string(0, 2, '%');
$sheet->write_string(0, 3, 'Term');
$sheet->write_string(0, 4, 'Replace by');

# Freeze thz header (first row)
$sheet->freeze_panes(1, 0);



my $nb = 0;

foreach my $item (sort {$term{$b} <=> $term{$a} or lc($a) cmp lc($b)} keys %term) {
        $nb ++;
        if ( $term{$item} < $from or
             $term{$item} * 100 / $nbDocs > $upto ) {
                $sheet->write($nb, 0, 'x', $format2);
                }
        else    {
                $sheet->write($nb, 0, ' ', $format2);
                }
        $sheet->write($nb, 1, $term{$item});
        $sheet->write($nb, 2, 1.0 * $term{$item} / $nbDocs, $format5);
        $sheet->write($nb, 3, $item);
        }

# Fermeture du fichier Excel
$xlsx->close();

move($output, $excel);
}

sub cleanup
{
my $signal = shift;

if ( defined $xlsx ) {
        $xlsx->close();
        }
if ( defined $output ) {
        unlink $output;
        }

if ( $signal =~ /^\d+\z/ ) {
        exit $signal;
        }
if ( $signal ) {
        print STDERR "Detecting signal SIG$signal \n";
        exit 9;
        }
else    {
        exit 0;
        }
}
