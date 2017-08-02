
open Util
open Rule

(* All the work will go here. *)
(* The arguments are an existing grammar (list of rules) and that grammar's start symbol. 
 * The return value is the entropy of the start symbol in that grammar.
 *)
let find_entropy rules start_symbol =

    (*** dummy code showing manipulation of rules ***)
    List.iter (fun r ->
        (* get_nonterm and get_weight are from rule.ml; float_of_weight is from util.ml, see also other weight functions there *)
        Printf.printf "This rule expands %s with weight %f\n" (get_nonterm r) (float_of_weight (get_weight r)) ;
        match (get_expansion r) with
        | PublicTerminating str -> Printf.printf "   and the right-hand side is the terminal '%s'\n" str
        | PublicNonTerminating (nts,_) -> Printf.printf "   and the right-hand side has nonterminals %s\n" (show_list (fun x -> x) (Nelist.to_list nts))

(* show_list is another util.ml function *)

    ) rules ;
    (*** end dummy code ***)

    (*** dummy code showing manipulation of matrices ***)
    let m = Matrix.create_square_matrix 2 (fun r -> fun c -> match (r,c) with (0,0) -> 4.0
                                                                            | (0,1) -> 7.0
                                                                            | (1,0) -> 2.0
                                                                            | (1,1) -> 6.0) in
    Printf.printf "Starting with this matrix:\n" ;
    Matrix.print m ;
    let mi = Matrix.invert m in
    Printf.printf "Here's its inverse:\n" ;
    Matrix.print mi ;
    Printf.printf "And here's their product:\n" ;
    Matrix.print (Matrix.multiply m mi) ;
    (*** end dummy code ***)

    0.0

let main () =
    let grammar_file = ref "" in
    let speclist = Arg.align( [("-g", Arg.Set_string(grammar_file), " WMCFG grammar file (obligatory)") ] ) in
    let usage_msg = Printf.sprintf "Usage: %s -g <grammar file>" Sys.argv.(0) in
    let superfluous_arg s = raise (Arg.Bad (Printf.sprintf "Bad extra argument: %s" s)) in
    Arg.parse speclist superfluous_arg usage_msg ;
    if (!grammar_file = "") then (
        Printf.eprintf "Must provide a grammar file\n" ;
        Arg.usage speclist usage_msg
    ) else (
        (* Everything's OK, let's do our thing ... *)
        let (rules,start_symbol) = Grammar.get_input_grammar (!grammar_file) in
        let entropy = find_entropy rules start_symbol in
        Printf.printf "(* \"entropy = %f\" *)\n" entropy
    )

let _ = if (!Sys.interactive) then () else main ()

