open Util
open Fsa

type item = ParseItem of string * (range list)

(* Provide our own equality function for use by item-keyed hashtables *)
module ItemHashtbl = Hashtbl.Make(
    struct
        type t = item
        let rec lists_equal eq list1 list2 =
            match (list1,list2) with
            | ([], [])       -> true
            | (x::xs, [])    -> false
            | ([], y::ys)    -> false
            | (x::xs, y::ys) -> if (eq x y) then (lists_equal eq xs ys) else false
        let equal item1 item2 =
            match (item1,item2) with (ParseItem(s1,ranges1), ParseItem(s2,ranges2)) ->
                (s1 = s2) && (lists_equal ranges_equal ranges1 ranges2)
        let hash = Hashtbl.hash
    end
)

type route = (item list) * Rule.r

(* A chart is a pair of hashtables. 
 * The first maps an item to its list of routes. 
 * The second maps a nonterminal to its list of items. *)
type chart = Chart of (route ItemHashtbl.t * (string,item) Hashtbl.t)

type item_route_status = NewItem | OldItemOldRoute | OldItemNewRoute

let get_nonterm = function ParseItem(nt,_) -> nt

let create_item str ranges = ParseItem(str, ranges)

let get_ranges = function ParseItem(_,rs) -> rs

let get_routes prop c =
  match c with
  | Chart (tbl,_) -> ItemHashtbl.find_all tbl prop

let debug_str item =
	let ParseItem (nt, ranges) = item in
	let show_range r =
		match (get_consumed_span r) with
		| Some (x,y) -> Printf.sprintf "%d:%d" (Fsa.index_of x) (Fsa.index_of y)
		| None -> Printf.sprintf "eps"
	in
	("[" ^^ nt ^^ (List.fold_left (^^) "" (map_tr show_range ranges)) ^^ "]")

let debug_str_long item chart =
	let ParseItem (nt, ranges) = item in
	let show_range r =
		match (get_consumed_span r) with
		| Some (x,y) -> Printf.sprintf "%d:%d" (Fsa.index_of x) (Fsa.index_of y)
		| None -> Printf.sprintf "eps"
	in
	let show_backpointer (items,r) = (show_weight (Rule.get_weight r)) ^^ ("(" ^ (String.concat "," (map_tr (fun i -> string_of_int (Hashtbl.hash i)) items)) ^ ")") in
	let backpointers_str = List.fold_left (^^) "" (map_tr show_backpointer (get_routes item chart)) in
	("[" ^^ (string_of_int (Hashtbl.hash item)) ^^ nt ^^ (List.fold_left (^^) "" (map_tr show_range ranges)) ^^ backpointers_str ^^ "]")

let compare_items i1 i2 =
        compare (debug_str i1) (debug_str i2)

let create i = Chart (ItemHashtbl.create i, Hashtbl.create i)

let add ?(is_new_item = None) c item route =
  match c with
  | Chart (tbl1,tbl2) ->
      let actually_is_new_item =
        match is_new_item with
          | Some b -> b
          | None -> (not (ItemHashtbl.mem tbl1 item))
      in
      if actually_is_new_item then Hashtbl.add tbl2 (get_nonterm item) item ;
      ItemHashtbl.add tbl1 item route

let get_items c nt =
  match c with
  | Chart (_,tbl) ->
    Hashtbl.find_all tbl nt

let get_status c item route =
  match (get_routes item c) with
  | [] -> NewItem
  | rs -> if (List.mem route rs) then OldItemOldRoute else OldItemNewRoute

let goal_item start_symbol fsa = ParseItem(start_symbol, [Range(fsa, goal_span fsa)])

(*** WARNING: Functions below here are very slow. Not recommended outside of debugging contexts. ***)

let all_items c =
  let Chart (tbl,_) = c in
  let t = ItemHashtbl.create 10000 in
  let add_if_new x _ acc =
    let is_new = not (ItemHashtbl.mem t x) in
    if is_new then (
      ItemHashtbl.add t x () ;
      x::acc
    ) else (
      acc
    )
  in
  ItemHashtbl.fold add_if_new tbl []

let length c = List.length (all_items c)

let iter_items c f = List.iter f (all_items c)

let map_items c f = List.map f (all_items c)
