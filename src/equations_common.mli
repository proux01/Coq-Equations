(**********************************************************************)
(* Equations                                                          *)
(* Copyright (c) 2009-2016 Matthieu Sozeau <matthieu.sozeau@inria.fr> *)
(**********************************************************************)
(* This file is distributed under the terms of the                    *)
(* GNU Lesser General Public License Version 2.1                      *)
(**********************************************************************)

open EConstr
open Environ
open Names

type 'a peuniverses = 'a * EConstr.EInstance.t

(* Options *)
val ocaml_splitting : bool ref
val simplify_withK : bool ref
val equations_transparent : bool ref

val debug : bool ref

(** Common flags *)
type flags = {
  polymorphic : bool;
  with_eqns : bool;
  with_ind : bool }  
  
(* Tactics *)
val to82 : 'a Proofview.tactic -> Proofview.V82.tac
val of82 : Proofview.V82.tac -> unit Proofview.tactic

(* Point-free composition *)
val ( $ ) : ('a -> 'b) -> ('c -> 'a) -> 'c -> 'b
val ( &&& ) : ('a -> 'b) -> ('c -> 'd) -> 'a * 'c -> 'b * 'd

val id : 'a -> 'a

val array_remove_last : 'a array -> 'a array
val array_chop_last : 'a array -> 'a array * 'a array
val rev_assoc : ('a -> 'b -> bool) -> 'a -> ('c * 'b) list -> 'c
val array_filter_map : ('a -> 'b option) -> 'a array -> 'b array

(* All the tails of [x1 ... xn] : [[xn]; [xn-1; xn] ...[x2 .. xn]] *)
val proper_tails : 'a list -> 'a list list

(* Stop at the first Some *)
val list_find_map_i : (int -> 'a -> 'b option) -> int -> 'a list -> 'b option

type esigma = Evd.evar_map ref

val head_of_constr : Evd.evar_map -> constr -> constr
val nowhere : 'a Locus.clause_expr
val dummy_loc : Loc.t option
type 'a located = 'a Loc.located

(** Fresh names *)
val fresh_id_in_env :
  Names.Id.t list -> Names.Id.t -> Environ.env -> Names.Id.t
val fresh_id :
  Names.Id.t list ->
  Names.Id.t -> Proof_type.goal Tacmach.sigma -> Names.Id.t

(** Refer to a tactic *)
val tac_of_string :
  string ->
  Tacexpr.r_dispatch Tacexpr.gen_tactic_arg list -> unit Proofview.tactic

type rel_context = EConstr.rel_context
type rel_declaration = EConstr.rel_declaration
type named_declaration = EConstr.named_declaration
type named_context = EConstr.named_context
       
(** Context lifting *)
val lift_rel_contextn :
  int -> int -> rel_context -> rel_context

val lift_rel_context : int -> rel_context -> rel_context

val lift_list : constr list -> constr list
val lift_constrs : int -> constr list -> constr list

(** Evars *)
val new_untyped_evar : unit -> Evd.evar

(** Checking *)
val check_term :
  Environ.env -> Evd.evar_map -> constr -> types -> unit
val check_type : Environ.env -> Evd.evar_map -> types -> unit
val typecheck_rel_context :
  Environ.env -> Evd.evar_map -> rel_context -> unit

val e_conv :
  env -> esigma -> constr -> constr -> bool

val e_type_of : env -> esigma -> constr -> types
						     
val reference_of_global : Globnames.global_reference -> Libnames.reference

(** Term manipulation *)

val mkNot : Environ.env -> Evd.evar_map ref -> constr -> constr
val mkProd_or_subst :
  rel_declaration ->
  types -> types
val mkProd_or_clear : Evd.evar_map -> rel_declaration -> constr -> constr
val it_mkProd_or_clear : Evd.evar_map -> 
  constr -> rel_declaration list -> constr
val mkLambda_or_subst :
  rel_declaration ->
  constr -> constr
val mkLambda_or_subst_or_clear : Evd.evar_map -> rel_declaration ->
                                 constr -> constr
val mkProd_or_subst_or_clear : Evd.evar_map -> rel_declaration ->
                               constr -> types
val it_mkProd_or_subst : types -> rel_declaration list -> constr
val it_mkProd_or_clean : constr -> rel_context -> constr
val it_mkLambda_or_subst :
  constr -> rel_declaration list -> constr
val it_mkLambda_or_subst_or_clear : Evd.evar_map -> constr -> rel_context -> constr
val it_mkProd_or_subst_or_clear : Evd.evar_map -> constr -> rel_context -> constr

val ids_of_constr : Evd.evar_map ->
  ?all:bool -> Idset.t -> constr -> Idset.t
val deps_of_var : Evd.evar_map -> Id.t -> env -> Idset.t
val idset_of_list : Id.t list -> Idset.t

val decompose_indapp : Evd.evar_map ->
  constr -> constr array -> constr * constr array

val refresh_universes_strict : Environ.env -> esigma -> types -> types

val new_global : Evd.evar_map -> Globnames.global_reference -> Evd.evar_map * constr
val e_new_global : esigma -> Globnames.global_reference -> constr
                                                                 
(** {6 Linking to Coq} *)

val contrib_name : string
val init_constant : string list -> string -> esigma -> constr
val init_reference : string list -> string -> Globnames.global_reference
val coq_constant : string list -> string -> Globnames.global_reference

val global_reference : Id.t -> Globnames.global_reference
(* Unsafe, avoid *)
val constr_of_ident : Id.t -> constr
  
val get_class : Evd.evar_map -> constr -> Typeclasses.typeclass * EConstr.EInstance.t

val make_definition :
  ?opaque:'a ->
  ?poly:Decl_kinds.polymorphic ->
  esigma ->
  ?types:constr -> constr -> Safe_typing.private_constants Entries.definition_entry

val declare_constant :
  Names.identifier ->
  constr ->
  constr option ->
  Decl_kinds.polymorphic ->
  Evd.evar_map -> Decl_kinds.logical_kind -> Names.constant

val declare_instance :
  Names.identifier ->
  Decl_kinds.polymorphic ->
  Evd.evar_map ->
  rel_context ->
  Typeclasses.typeclass peuniverses -> constr list -> constr

(** Standard datatypes *)

type logic_ref = Globnames.global_reference lazy_t
							       
type logic = {
  logic_eq_ty : logic_ref;
  logic_eq_refl: logic_ref;
  logic_eq_case: logic_ref;
  logic_eq_elim: logic_ref;
  logic_sort : Term.sorts_family;
  logic_zero : logic_ref;
  logic_one : logic_ref;
  logic_one_val : logic_ref;
  logic_product : logic_ref;
  logic_pair : logic_ref;
  (* logic_sigma : logic_ref; *)
  (* logic_pair : logic_ref; *)
  (* logic_fst : logic_ref; *)
  (* logic_snd : logic_ref; *)
}

val set_logic : logic -> unit
val prop_logic : logic
val type_logic : logic

val get_sort : unit -> Term.sorts_family
val get_eq : unit -> Globnames.global_reference
val get_eq_refl : unit -> Globnames.global_reference
val get_eq_case : unit -> Globnames.global_reference
val get_eq_elim : unit -> Globnames.global_reference

val get_one : unit -> Globnames.global_reference
val get_one_prf : unit -> Globnames.global_reference
val get_zero : unit -> Globnames.global_reference

val coq_unit : Globnames.global_reference lazy_t
val coq_tt : Globnames.global_reference lazy_t

  
val coq_prod : esigma -> constr
val coq_pair : esigma -> constr

val coq_sigma : Globnames.global_reference lazy_t
val coq_sigmaI : Globnames.global_reference lazy_t
val coq_pr1 : Names.projection lazy_t
val coq_pr2 : Names.projection lazy_t
			    
val coq_zero : Globnames.global_reference lazy_t
val coq_succ : Globnames.global_reference lazy_t
val coq_nat : Globnames.global_reference lazy_t
val coq_nat_of_int : int -> Term.constr
val int_of_coq_nat : Term.constr -> int

val coq_eq : Globnames.global_reference Lazy.t
val coq_eq_refl : Globnames.global_reference lazy_t
val coq_heq : Globnames.global_reference lazy_t
val coq_heq_refl : Globnames.global_reference lazy_t
val coq_fix_proto : Globnames.global_reference lazy_t
val fresh_logic_sort : esigma -> constr
val mkapp : Environ.env ->
  esigma ->
  Globnames.global_reference -> constr array -> constr
val mkEq : Environ.env ->
  esigma -> types -> constr -> constr -> constr
val mkRefl : Environ.env -> esigma -> types -> constr -> constr
val mkHEq : Environ.env ->
  esigma ->
  types -> constr -> types -> constr -> constr
val mkHRefl : Environ.env -> esigma -> types -> constr -> constr

(** Bindings to theories/ files *)

val equations_path : string list
val below_path : string list
val list_path : string list
val subterm_relation_base : string

val functional_induction_class :
  Evd.evar_map -> Evd.evar_map * Typeclasses.typeclass peuniverses
val functional_elimination_class :
  Evd.evar_map -> Evd.evar_map * Typeclasses.typeclass peuniverses
val dependent_elimination_class :
  esigma -> Typeclasses.typeclass peuniverses

val coq_wellfounded_class : esigma -> constr
val coq_wellfounded : esigma -> constr
val coq_relation : esigma -> constr
val coq_clos_trans : esigma -> constr
val coq_id : esigma -> constr
val coq_list_ind : esigma -> constr
val coq_list_nil : esigma -> constr
val coq_list_cons : esigma -> constr
val coq_noconfusion_class : Globnames.global_reference lazy_t
val coq_inacc : Globnames.global_reference Lazy.t
val coq_block : Globnames.global_reference Lazy.t
val coq_hide : Globnames.global_reference Lazy.t
val coq_hidebody : Globnames.global_reference Lazy.t
val coq_add_pattern : Globnames.global_reference Lazy.t
val coq_end_of_section_id : Names.Id.t
val coq_end_of_section_constr : esigma -> constr
val coq_end_of_section : esigma -> constr
val coq_end_of_section_ref : Globnames.global_reference Lazy.t
val coq_notT : esigma -> constr
val coq_ImpossibleCall : esigma -> constr
val unfold_add_pattern : unit Proofview.tactic lazy_t

val observe : string -> Proofview.V82.tac -> Proofview.V82.tac
  
val below_tactics_path : Names.dir_path
val below_tac : string -> Names.kernel_name
val tacident_arg :
  Names.Id.t ->
  < constant : 'a; dterm : 'b; level : 'c; name : 'd; pattern : 'e;
    reference : Libnames.reference; tacexpr : 'f; term : 'g > Tacexpr.gen_tactic_arg
val tacvar_arg :
  Names.Id.t ->
  < constant : 'a; dterm : 'b; level : Genarg.rlevel; name : 'c;
    pattern : 'd; reference : 'e; tacexpr : 'f; term : 'g > Tacexpr.gen_tactic_arg
val rec_tac :
  'f ->
  Names.Id.t ->
  < constant : 'a; dterm : 'b; level : Genarg.rlevel; name : 'c;
    pattern : 'd; reference : Libnames.reference; tacexpr : 'e; term : 'f; >
	   Tacexpr.gen_tactic_expr
val rec_wf_tac :
  'a ->
  Names.Id.t ->
  'a ->
  < constant : 'b; dterm : 'c; level : Genarg.rlevel; name : 'd;
    pattern : 'e; reference : Libnames.reference; tacexpr : 'f; term : 'a;>
	   Tacexpr.gen_tactic_expr
val unfold_recursor_tac : unit -> unit Proofview.tactic
val equations_tac_expr :
  unit ->
  < constant : 'a; dterm : 'b; level : 'c; name : 'd; pattern : 'e;
    reference : Libnames.reference; tacexpr : 'f; term : 'g >
								    Tacexpr.gen_tactic_expr
val solve_rec_tac_expr :
  unit ->
  < constant : 'a; dterm : 'b; level : 'c; name : 'd; pattern : 'e;
    reference : Libnames.reference; tacexpr : 'f; term : 'g >
								    Tacexpr.gen_tactic_expr
val equations_tac : unit -> unit Proofview.tactic
val set_eos_tac : unit -> unit Proofview.tactic
val solve_rec_tac : unit -> unit Proofview.tactic
val find_empty_tac : unit -> unit Proofview.tactic
val pi_tac : unit -> unit Proofview.tactic
val noconf_tac : unit -> unit Proofview.tactic
val eqdec_tac : unit -> unit Proofview.tactic
val simpl_equations_tac : unit -> unit Proofview.tactic
val solve_equation_tac : Globnames.global_reference -> unit Proofview.tactic
val impossible_call_tac : Globnames.global_reference -> Genarg.glevel Genarg.generic_argument
val depelim_tac : Names.Id.t -> unit Proofview.tactic
val do_empty_tac : Names.Id.t -> unit Proofview.tactic
val depelim_nosimpl_tac : Names.Id.t -> unit Proofview.tactic
val simpl_dep_elim_tac : unit -> unit Proofview.tactic
val depind_tac : Names.Id.t -> unit Proofview.tactic

(** Unfold the first occurrence of a constant declared unfoldable in db
  (with Hint Unfold) *)
val autounfold_first :
  Hints.hint_db_name list ->
  Locus.hyp_location option ->
  Proof_type.goal Tacmach.sigma -> Proof_type.goal list Evd.sigma

type hintdb_name = string
val db_of_constr : Term.constr -> hintdb_name
val dbs_of_constrs : Term.constr list -> hintdb_name list

val pr_smart_global :
  Libnames.reference Misctypes.or_by_notation -> Pp.std_ppcmds
val string_of_smart_global :
  Libnames.reference Misctypes.or_by_notation -> string
val ident_of_smart_global :
  Libnames.reference Misctypes.or_by_notation -> identifier

val pf_get_type_of : Goal.goal Evd.sigma -> constr -> types

val move_after_deps : Names.Id.t -> constr -> unit Proofview.tactic

val extended_rel_vect : int -> rel_context -> constr array
val extended_rel_list : int -> rel_context -> constr list
val to_tuple : rel_declaration -> Names.Name.t * constr option * constr
val to_named_tuple : named_declaration -> Names.Id.t * constr option * constr
val of_tuple : Names.Name.t * constr option * constr -> rel_declaration
val of_named_tuple : Names.Id.t * constr option * constr -> named_declaration

val get_type : rel_declaration -> constr
val get_name : rel_declaration -> Names.Name.t
val get_value : rel_declaration -> constr option
val make_assum : Names.Name.t -> constr -> rel_declaration
val make_def : Names.Name.t -> constr option -> constr -> rel_declaration
val make_named_def : Names.Id.t -> constr option -> constr -> named_declaration
val to_context : (Names.Name.t * constr option * constr) list -> rel_context

val localdef : Constr.t -> Entries.local_entry
val localassum : Constr.t -> Entries.local_entry
val named_of_rel_context : ?keeplets:bool -> (unit -> Names.Id.t) -> rel_context -> Vars.substl * constr list * named_context
val rel_of_named_context : named_context -> rel_context * Names.Id.t list
val subst_rel_context : int -> Vars.substl -> rel_context -> rel_context
val get_id : named_declaration -> Names.Id.t
val get_named_type : named_declaration -> constr
val get_named_value : named_declaration -> constr option

val lookup_rel : int -> rel_context -> rel_declaration
val fold_named_context_reverse : ('a -> named_declaration -> 'a) -> init:'a -> named_context -> 'a
val map_rel_context : (constr -> constr) -> rel_context -> rel_context
val map_rel_declaration : (constr -> constr) -> rel_declaration -> rel_declaration
val map_named_declaration : (constr -> constr) -> named_declaration -> named_declaration
val map_named_context : (constr -> constr) -> named_context -> named_context
val lookup_named : Id.t -> named_context -> named_declaration

val to_evar_map : Evd.evar_map -> Evd.evar_map
val of_evar_map : Evd.evar_map -> Evd.evar_map

val pp : Pp.std_ppcmds -> unit
val user_err_loc : (Loc.t option * string * Pp.std_ppcmds) -> 'a
val error : string -> 'a
val errorlabstrm : string -> Pp.std_ppcmds -> 'a
val is_anomaly : exn -> bool
val print_error : exn -> Pp.std_ppcmds
val anomaly : ?label:string -> Pp.std_ppcmds -> 'a
                                
val nf_betadeltaiota : Reductionops.reduction_function

val subst_telescope : constr -> rel_context -> rel_context
val subst_in_ctx : int -> constr -> rel_context -> rel_context
val set_in_ctx : int -> constr -> rel_context -> rel_context
val subst_in_named_ctx :
  Names.Id.t -> constr -> named_context -> named_context

val evar_declare : named_context_val ->
  Evd.evar -> 
  EConstr.types -> ?src:(Evar_kinds.t Loc.located) -> Evd.evar_map -> Evd.evar_map

val new_evar :            Environ.env ->
           Evd.evar_map ->
           ?src:Evar_kinds.t Loc.located ->
           types -> Evd.evar_map * constr

val new_type_evar :            Environ.env ->
           Evd.evar_map -> 
           ?src:Evar_kinds.t Loc.located -> Evd.rigid ->
           Evd.evar_map * (constr * Term.sorts)

val empty_hint_info : 'a Vernacexpr.hint_info_gen

val evar_absorb_arguments :
  Environ.env -> Evd.evar_map ->
  existential ->
  constr list -> Evd.evar_map * existential


val hintdb_set_transparency :
  Constant.t -> bool -> Hints.hint_db_name -> unit
  
(** To add to the API *)
val to_peuniverses : 'a Constr.puniverses -> 'a peuniverses
val from_peuniverses : Evd.evar_map -> 'a peuniverses -> 'a Constr.puniverses

val is_global : Evd.evar_map -> Globnames.global_reference -> constr -> bool
val constr_of_global_univ : Evd.evar_map -> Globnames.global_reference peuniverses -> constr
val smash_rel_context : Evd.evar_map -> rel_context -> rel_context (** expand lets in context *)

val rel_vect : int -> int -> constr array
val applistc : constr -> constr list -> constr

val instance_constructor : Evd.evar_map -> Typeclasses.typeclass peuniverses -> constr list ->
  constr option * types
val decompose_appvect : Evd.evar_map -> constr -> constr * constr array

val dest_ind_family : Inductiveops.inductive_family -> inductive peuniverses * constr list
val prod_appvect : Evd.evar_map -> constr -> constr array -> constr
val beta_appvect : Evd.evar_map -> constr -> constr array -> constr

val find_rectype : Environ.env -> Evd.evar_map -> types -> Inductiveops.inductive_family * constr list
