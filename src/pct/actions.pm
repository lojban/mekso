# $Id$

=begin comments

mekso::Grammar::Actions - ast transformations for mekso

This file contains the methods that are used by the parse grammar
to build the PAST representation of an mekso program.
Each method below corresponds to a rule in F<src/parser/grammar.pg>,
and is invoked at the point where C<{*}> appears in the rule,
with the current match object as the first argument.  If the
line containing C<{*}> also has a C<#= key> comment, then the
value of the comment is passed as the second argument to the method.

=end comments

class mekso::Grammar::Actions;

sub instantiate_class($class_name, $node) {
    my $class := PAST::Var.new(:name($class_name), :scope('package'));
    return PAST::Op.new(:pasttype('callmethod'), :name('new'), :node($node), $class);
}

method TOP($/) {
    my $past := PAST::Block.new( :blocktype('declaration'), :node( $/ ), :hll('mekso') );
    for $<bridi> {
        $past.push( $_.ast );
    }
    make $past;
}


method mekso($/, $key) {
    my $past := PAST::Op.new( :name(~$<operator>), :pasttype('call'), :node( $/ ) );
    if ($key eq "unary") { 
        $past.push( $<term>.ast );
    } else {
        for $<term> {
            $past.push( $_.ast );
        }
    }

    make $past;
}

method bridi($/, $key) {
    my $bridi := instantiate_class(~$<selbri>, $/);

    if ($key eq 'observative') {
        $bridi.push(PAST::Op.new( :name("zo'e"), :pasttype('call') ));
    }

    for $<sumti> {
        $bridi.push($_.ast);
    }
    
    if $<meiclause> {
        $bridi.push($<meiclause>[0].ast);
    }

    if $<maiclause> {
        $bridi.push($<maiclause>[0].ast);
    }

    make $bridi;
}

method maiclause($/) {
    $<nahusni>.ast.named('mai');
    make $<nahusni>.ast;
}

method meiclause($/) {
    $<nahusni>.ast.named('mei');
    make $<nahusni>.ast;
}

method sumti($/, $key) {
    make $<namcu>.ast;
}

##  expression:
##    This is one of the more complex transformations, because
##    our grammar is using the operator precedence parser here.
##    As each node in the expression tree is reduced by the
##    parser, it invokes this method with the operator node as
##    the match object and a $key of 'reduce'.  We then build
##    a PAST::Op node using the information provided by the
##    operator node.  (Any traits for the node are held in $<top>.)
##    Finally, when the entire expression is parsed, this method
##    is invoked with the expression in $<expr> and a $key of 'end'.
method expression($/, $key) {
    if ($key eq 'end') {
        make $<expr>.ast;
    }
    else {
        my $past := PAST::Op.new( :name($<type>),
                                  :pasttype($<top><pasttype>),
                                  :pirop($<top><pirop>),
                                  :lvalue($<top><lvalue>),
                                  :node($/)
                                );
        for @($/) {
            $past.push( $_.ast );
        }
        make $past;
    }
}


##  term:
##    Like 'statement' above, the $key has been set to let us know
##    which term subrule was matched.
method term($/, $key) {
    make $/{$key}.ast;
}


method value($/, $key) {
    make $/{$key}.ast;
}

method namcu($/,$key) {
    make $/{$key}.ast;
} 

method nahusni($/) {
    my %PA;
    %PA<no> := 0;
    %PA<pa> := 1;
    %PA<re> := 2;
    %PA<ci> := 3;
    %PA<vo> := 4;
    %PA<mu> := 5;
    %PA<xa> := 6;
    %PA<ze> := 7;
    %PA<bi> := 8;
    %PA<so> := 9;
    my $num := 0;
    for $<PA1> {
        $num := $num * 10;
        $num := $num + %PA{~$_};
    }
    if ~$<prefixsign>[0] eq "ni'u" {
        $num := -$num;
    }
    make PAST::Val.new( :value( $num ), :returns('BigNum'), :node($/) );
}


method quote($/) {
    make PAST::Val.new( :value( $<string_literal>.ast ), :node($/) );
}


# Local Variables:
#   mode: perl6
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:

