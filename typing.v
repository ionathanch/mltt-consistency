From WR Require Import syntax join.
From Coq Require Import
  Sets.Relations_2
  ssreflect
  Program.Basics.
From Hammer Require Import Tactics.

Definition context := nat -> tm.

Definition dep_ith (Γ : context) (x : fin) :=
  ren_tm (Nat.add (S x)) (Γ x).

Lemma dep_ith_ren_tm (Γ : context) (A : tm) (x : fin) :
  dep_ith (A .: Γ) (S x) = ren_tm shift (dep_ith Γ x).
Proof.
  case : x => [|x].
  - rewrite /dep_ith; asimpl.
    reflexivity.
  - rewrite /dep_ith.
    asimpl.
    f_equal.
Qed.

#[export]Hint Unfold dep_ith : core.

Tactic Notation "asimpldep" := repeat (progress (rewrite /dep_ith; asimpl)).

Inductive Wt (n : nat) (Γ : context) : tm -> tm -> Prop :=
| T_Var i :
  i < n ->
  (* ------ *)
  Wt n Γ (var_tm i) (dep_ith Γ i)
| T_False :
  (* -------- *)
  Wt n Γ tFalse tUniv
| T_Pi A B :
  Wt n Γ A tUniv ->
  Wt (S n) (A .: Γ) B tUniv ->
  (* --------------------- *)
  Wt n Γ (tPi A B) tUniv
| T_Abs A a B :
  UWf n Γ A ->
  Wt (S n) (A .: Γ) a B ->
  (* -------------------- *)
  Wt n Γ (tAbs A a) (tPi A B)
| T_App a A B b :
  Wt n Γ a (tPi A B) ->
  Wt n Γ b A ->
  (* -------------------- *)
  Wt n Γ (tApp a b) (subst_tm (b..) B)
| T_Conv a A B :
  Wt n Γ a A ->
  UWf n Γ B ->
  Join A B ->
  (* ----------- *)
  Wt n Γ a B
with UWf (n : nat) (Γ : context) : tm -> Prop :=
| U_Univ :
  UWf n Γ tUniv
| U_False :
  UWf n Γ tFalse
| U_Pi A B :
  UWf n Γ A ->
  UWf (S n) (A .: Γ) B ->
  UWf n Γ (tPi A B)
| U_Embed A :
  Wt n Γ A tUniv ->
  UWf n Γ A.

Definition ProdSpace (PA : tm -> Prop) (PF : tm -> (tm -> Prop) -> Prop) (b : tm) :=
  forall a, PA a -> exists PB, PF a PB /\ PB (tApp b a).

Inductive InterpUniv : tm -> (tm -> Prop) -> Prop :=
| InterpUniv_False : InterpUniv tFalse (const False)
| InterpUniv_Fun A B PA (PF : tm -> (tm -> Prop) -> Prop) :
  InterpUniv A PA ->
  (forall a PB, PA a -> PF a PB -> InterpUniv (subst_tm (a..) B) PB) ->
  InterpUniv (tPi A B) (ProdSpace PA PF)
| InterpUniv_Step A0 A1 PA1 :
  Par A0 A1 ->
  InterpUniv A1 PA1 ->
  InterpUniv A0 PA1.
