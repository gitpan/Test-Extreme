package Test::Extreme;

use strict;
use Carp;

use vars qw($VERSION @ISA @EXPORT);

$VERSION = '0.11';
 
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(
    assert
    assert_true
    assert_false
    assert_passed
    assert_failed
    assert_some
    assert_none
    assert_is_array
    assert_equals
    assert_contains
    assert_subset
    assert_is_array
    assert_is_hash
    assert_size
    assert_keys
    assert_is_string
    run_tests
);

sub assert($)       { confess "Assertion failed.\n$@" if !$_[0] ; undef $@ }
sub assert_true($)  { assert $_[0]    }
sub assert_false($) { assert ! $_[0]  }
sub assert_passed() { assert_false $@ }
sub assert_failed() { assert_true  $@ }
sub assert_some($)  { assert_true  $_[0] }
sub assert_none($)  { assert_false $_[0] }

sub assert_equals_string($$) { assert_true($_[0] eq $_[1]) }

sub assert_is_array($);

sub assert_equals_array($$) {
    my ($list0, $list1) = @_;
    assert_is_array $list0;
    assert_is_array $list1;
    assert_equals_string scalar @$list0, scalar @$list1;
    for (my $i = 0 ; $i < @$list0 ; ++$i) {
        assert_equals( $list0->[$i], $list1->[$i] );
    }
}

sub assert_equals_hash($$) {
    my ($hash0, $hash1) = @_;
    assert_equals_string scalar keys %$hash0, scalar keys %$hash1;
    for my $key (keys %{$hash0}) {
        assert_true exists $hash1->{$key};
        assert_equals($hash0->{$key}, $hash1->{$key});
    }
}

sub assert_equals($$) { 
    assert_equals_string $_[0], $_[1] if ref $_[0] eq '';
    assert_equals_array  $_[0], $_[1] if ref $_[0] eq 'ARRAY';
    assert_equals_hash   $_[0], $_[1] if ref $_[0] eq 'HASH';
}

sub assert_contains($$) {
    my ($element, $list) = @_;
    assert_equals "", ref $element;
    assert_equals "ARRAY", ref $list;
    eval { assert_true grep { $_ eq $element } @$list } ;
    if ($@) {
        my $list_text = "[" . join(" " => @$list) . "]";
        confess "Did not find $element in $list_text.\n$@" ; 
    }
}

sub assert_subset($$) {
    my ($list1, $list2) = @_;
    assert_equals "ARRAY", ref $list1;
    assert_equals "ARRAY", ref $list2;
    for my $element (@$list1) 
    { assert_contains $element, $list2 }
}

sub assert_is_array($) { assert_equals 'ARRAY', ref $_[0] }

sub assert_is_hash($)  { assert_equals 'HASH',  ref $_[0] }

sub assert_size($$) { 
    my ($size, $array) = @_;
    assert_is_array $array;
    assert_equals $size, scalar @$array
}

sub assert_keys($$) { 
    my ($keys, $hash) = @_;
    assert_is_hash  $hash;
    assert_is_array $keys;
    my @actual_keys   = sort keys %{$hash}; 
    my @expected_keys = sort @$keys;
    assert_equals \@expected_keys, \@actual_keys
}

sub assert_is_string($) { 
    my ($string) = @_;
    assert_equals '', ref $string;
    assert ($string =~ /\S/)
}

sub _list_symbols {
    use vars qw /$symbol $sym @sym %sym/;

    my $pkg = shift;
    my $prefix = shift;

    no strict 'refs';
    my  %pkg_keys = %{$pkg};
    use strict;

    my $symbols = [];
    foreach $symbol (keys %pkg_keys) {
        my $is_word = ($symbol =~ /^[\:\w]+$/s);
        next if ! $is_word;
        my $symbol_path = $prefix . $pkg . $symbol ;
        push @$symbols, $symbol if eval qq[ defined($symbol_path) ];
    }
    @$symbols = sort @$symbols;
    return $symbols;
}

sub _list_subs($)     { return _list_symbols shift, '&' }

sub _list_packages($) { 
    my $list = _list_symbols shift, '%' ;
    @$list = grep { /::$/ } @$list ;
    return $list;
}

sub _list_tests($) {
    my ($pkg) = @_;
    my $list = _list_subs $pkg;
    @$list = map { $pkg . $_ } grep { /^_*[tT]est/ } @$list ;
    return $list;
}

sub _execute_tests($$$) {
    my ($all_tests, $failure_messages, $output) = @_;
    for my $test (@$all_tests) {
        no strict 'refs';
        eval { &{$test} };
        use strict;
        if ($@) { 
            print "F" if $output;
            $failure_messages->{$test} = $@;
        } 
        else { print "." if $output }
    }
    print "\n" if $output;
}

sub _print_failure_messages($$) {
    my ($all_tests, $failure_messages) = @_;
    for my $test (sort keys %{$failure_messages}) {
        print "$test: $failure_messages->{$test}"
    }
    print "\n";
    my $test_count = scalar @$all_tests;
    my $fail_count = scalar keys %{$failure_messages};
    my $pass_count = $test_count - $fail_count;
    my $test_or_tests = $test_count == 1 ? "test" : "tests";
    if ($fail_count == 0) { 
        print "OK ($test_count $test_or_tests)\n" 
    }
    else {
        print "Failures!!!\n\n";
        print "Runs: $test_count,  Passes: $pass_count,  Fails: $fail_count\n";
    }
    print "\n";
}

sub run_tests {
    my @pkgs = map { $_ . "::" } ( 'main' , @_);
    my $all_tests = [];
    for my $pkg (@pkgs) { push @$all_tests, @{ _list_tests $pkg }; }

     my $failure_messages = {};
      _execute_tests $all_tests, $failure_messages, 1;
     _print_failure_messages $all_tests, $failure_messages;
}

1;

__END__

=head1 NAME

    Test::Extreme - A perlish unit testing framework

=head1 SYNOPSIS

    # In your code module ModuleOne.pm

    sub foo { return 23 };
    sub bar { return 42 };

    # In your test module ModuleOneTest.pm

    use Test::Extreme;

    sub test_foo { assert_equals foo, 23 }    
    sub test_bar { assert_equals bar, 42 }    

    # To run these tests on the command line type

    perl -MModuleOneTest -e run_tests

    # If you have tests in several modules (say in
    # ModuleOneTest.pm, ModuleTwoTest.pm and ModuleThreeTest.pm,
    # create AllTests.pm containing precisely the following:

    use ModuleOneTest;
    use ModuleTwoTest;
    use ModuleThreeTest;

    1;

    # To run all of these tests on the command line type

    perl -MAllTests -e run_tests

    # If you have tests in different namespaces you can run them
    # by typing (for example)

    perl -MAllTests -e 'run_tests "namespace1", "namespace2"'


    # Also take a look at Test/Extreme.pm which includes its own
    # unit tests for how to instrument a module with unit tests

=head1 DESCRIPTION

    Test::Extreme is a perlish port of the xUnit testing
    framework. It is in the spirit of JUnit, the unit testing
    framework for Java, by Kent Beck and Erich Gamma. Instead of
    porting the implementation of JUnit we have ported its spirit
    to Perl.

    The target market for this module is perlish people
    everywhere who value laziness above all else.

    Test::Extreme is especially written so that it can be easily
    and concisely used from Perl programs without turning them
    into Java and without inducing object-oriented nightmares in
    innocent Perl programmers. It has a shallow learning curve.
    The goal is to adopt the unit testing idea minus the OO
    cruft, and to make the world a better place by promoting the
    virtues of laziness, impatience and hubris.

    You test a given unit (a script, a module, whatever) by using
    Test::Extreme, which exports the following routines into your
    namespace:

    assert $x            - $x is true
    assert_true $x       - $x is true
    assert_false $x      - $x is not true
    assert_passed        - the last eval did not die ($@ eq "")
    assert_failed        - the last eval caused a die ($@ ne "")
    assert_some $x       - $x is true
    assert_none          - $x is false
    assert_equals $x, $y - recursively tests arrayrefs, hashrefs
                           and strings to ensure they have the same 
                           contents
    assert_contains $string, $list 
                         - $list contains $string assert_subset 
                           $element_list, $list - $element_list is 
                           a subset of $list (both are arrayrefs)
    assert_is_array $x   - $x is an arrayref
    assert_is_hash $x    - $x is a hashref
    assert_is_string $x  - $x is a scalar
    assert_size N, $list - the arrayref contains N elements
    assert_keys ['k1', 'k2'], $hash 
                         - $hash contains k1, k2 as keys
    run_tests            - run all tests in package main
    run_tests NS1, NS2, ...
                         - run all tests in package main, NS1,
                           NS2, and so on

    For an example on how to use these assert take a look at
    Test/ExtremeTest.pm which shows different ways of using these
    asserts.

    Currently this requires that all your tests live in the
    main:: namespace. If you are not sure what that means things
    will probably just work seamlessly.

    The function run_tests finds all functions that start with
    the word test (preceded by zero or more underscores) and runs
    them one at a time.

    Running the tests generates a status line (a "." for every
    successful test run, or an "F" for any failed test run), a
    summary result line ("OK" or "FAILURES!!!") and zero or more
    lines containing detailed error messages for any failed
    tests.

=head1 AUTHOR

    Copyright (c) 2002 Asim Jalis, <asimjalis@acm.org>.

    All rights reserved. This program is free software; you can
    redistribute it and/or modify it under the same terms as Perl
    itself.

=head1 SEE ALSO

    - Test::Unit
    - Test::SimpleUnit

=cut
