Require Import join normalform imports.

Definition tm_set := tm -> Prop.
Definition tm_rel := tm -> tm -> Prop.

(* (* These are only needed for neutrals; I omit them for now *)
Definition wne_coherent a b := exists c, a ⇒* c /\ b ⇒* c /\ ne c.

Lemma ne_preservations a b (h : a ⇒* b) : ne a -> ne b.
Proof.
  elim : a b /h => //.
  sfirstorder use:ne_preservation.
Qed.

Lemma wne_coherent_trans a b c :
  wne_coherent a b -> wne_coherent b c -> wne_coherent a c.
Proof.
  - move => [d [rad [rbd ned]]] [f [rbf [rcf nef]]].
    have [h [rdh rfh]] : _ := Pars_confluent b d f rbd rbf.
    exists h. hauto l:on use:rtc_transitive, ne_preservations.
Qed.
*)

Definition ProdSpace (RA : tm_rel) (RF : tm -> tm_rel -> Prop) (b0 b1 : tm) :=
  forall a0 a1 RB, RA a0 a1 -> RF a0 RB -> RF a1 RB -> RB (tApp b0 a0) (tApp b1 a1).

Definition ProdType (RA : tm_rel) (PA : tm_set) (PF : tm -> tm_set -> Prop) (C : tm) :=
  exists A' B', C ⇒* tPi A' B' /\ PA A' /\
    (forall a0 a1 PB, RA a0 a1 -> PF a0 PB -> PF a1 PB -> PB (B'[a0..]) /\ PB (B'[a1..])).

Definition EqSpace (RA : tm_rel) (a b : tm) (p1 p2 : tm) :=
  p1 ⇒* tRefl /\ p2 ⇒* tRefl /\ RA a b.

Definition EqType (P : tm_set) (RA : tm_rel) (a b : tm) (B : tm) :=
  exists a' b' A', B ⇒* tEq a' b' A' /\ P A' /\ RA a a' /\ RA b b'.
  (* what about RA a0 b1, RA a1 b0? *)

Reserved Notation "⟦ A ⟧ i , I ↘ R , P" (at level 70).
Inductive InterpExt (i : nat) (I : forall j, j < i -> tm_rel) : tm -> tm_rel -> tm_set -> Prop :=
(* | InterpExt_Ne A : ne A -> ⟦ A ⟧ i , I ↘ wne_coherent *)
| InterpExt_Fun A B RA RF PA PF :
  ⟦ A ⟧ i , I ↘ RA , PA ->
  (forall a0 a1, RA a0 a1 -> exists RB, RF a0 RB /\ RF a1 RB) ->
  (forall a0 a1, RA a0 a1 -> exists PB, PF a0 PB /\ PF a1 PB) ->
  (forall a RB PB, RF a RB -> PF a PB -> ⟦ B[a..] ⟧ i , I ↘ RB , PB) ->
  ⟦ tPi A B ⟧ i , I ↘ (ProdSpace RA RF) , (ProdType RA PA PF)
| InterpExt_Univ j lt :
  ⟦ tUniv j ⟧ i , I ↘ (I j lt) , (fun A => A ⇒* tUniv j)
| InterpExt_Eq a b A RA P :
  ⟦ A ⟧ i , I ↘ RA , P ->
  ⟦ tEq a b A ⟧ i , I ↘ (EqSpace RA a b) , (EqType P RA a b)
| InterpExt_Step A0 A1 R P:
  A0 ⇒ A1 ->
  ⟦ A1 ⟧ i , I ↘ R , P ->
  ⟦ A0 ⟧ i , I ↘ R , P
where "⟦ A ⟧ i , I ↘ R , P" := (InterpExt i I A R P).

(* Two types A0, A1 are related if they have the same term interpretation RA
   and if they are related to one another by their respective relation sets. *)
Equations InterpUnivN (n : nat) : tm -> tm_rel -> tm_set -> Prop by wf n lt :=
  InterpUnivN n := InterpExt n (fun m _ A0 A1 =>
    exists RA P0 P1,
      InterpUnivN m A0 RA P0 /\
      InterpUnivN m A1 RA P1 /\
      P0 A1 /\ P1 A0).
Notation "⟦ A ⟧ i ↘ R , P" := (InterpUnivN i A R P) (at level 70).

(*
Reserved Notation "⟦ A ⟧ ~ ⟦ B ⟧ i , I" (at level 70, i at next level).
Inductive PerType (i : nat) (I : forall j, j < i -> tm_rel) : tm_rel :=
(* | PerType_Ne A B :
  wne_coherent A B ->
  ⟦ A ⟧ ~ ⟦ B ⟧ i , I *)
| PerType_Fun A0 A1 B0 B1 RA :
  ⟦ A0 ⟧ ~ ⟦ A1 ⟧ i , I ->
  ⟦ A0 ⟧ i , I ↘ RA ->
  ⟦ A1 ⟧ i , I ↘ RA ->
  (forall a0 a1, RA a0 a1 -> ⟦ B0[a0..] ⟧ ~ ⟦ B1[a1..] ⟧ i , I) ->
  ⟦ tPi A0 B0 ⟧ ~ ⟦ tPi A1 B1 ⟧ i , I
| PerType_Univ j :
  j < i ->
  ⟦ tUniv j ⟧ ~ ⟦ tUniv j ⟧ i , I
| PerType_Eq a0 a1 b0 b1 A0 A1 RA :
  ⟦ A0 ⟧ ~ ⟦ A1 ⟧ i , I ->
  ⟦ A0 ⟧ i , I ↘ RA ->
  ⟦ A1 ⟧ i , I ↘ RA ->
  RA a0 a1 -> RA b0 b1 -> (* what about RA a0 b1, RA a1 b0? *)
  ⟦ tEq a0 b0 A0 ⟧ ~ ⟦ tEq a1 b1 A1 ⟧ i , I
| PerType_Step A0 A1 B0 B1 :
  A0 ⇒ A1 -> B0 ⇒ B1 ->
  ⟦ A1 ⟧ ~ ⟦ B1 ⟧ i , I ->
  ⟦ A0 ⟧ ~ ⟦ B0 ⟧ i , I
where "⟦ A ⟧ ~ ⟦ B ⟧ i , I" := (PerType i I A B).

Equations PerTypeN (n : nat) : tm_rel by wf n lt :=
  PerTypeN n := PerType n (fun m _ => PerTypeN m).

Definition InterpUnivN (n : nat) : tm -> tm_rel -> Prop :=
  InterpExt n (fun m _ => PerTypeN m).

Notation "⟦ A ⟧ ~ ⟦ B ⟧ i" := (PerTypeN i A B) (at level 70).
Notation "⟦ A ⟧ i ↘ S" := (InterpUnivN i A S) (at level 70).
*)

Lemma InterpUnivN_nolt n :
  InterpUnivN n = InterpExt n (fun m _ A0 A1 =>
    exists RA P0 P1,
      InterpUnivN m A0 RA P0 /\
      InterpUnivN m A1 RA P1 /\
      P0 A1 /\ P1 A0).
Proof. simp InterpUnivN. reflexivity. Qed.

(* Constructors *)

Lemma InterpExt_Univ' i I j lt R P :
  R = I j lt ->
  P = (fun A => A ⇒* tUniv j) ->
  ⟦ tUniv j ⟧ i , I ↘ R , P.
Proof. hauto lq:on ctrs:InterpExt. Qed.

Lemma InterpExt_Eq' i I a b A RA PA R P :
  R = EqSpace RA a b ->
  P = EqType PA RA a b ->
  ⟦ A ⟧ i , I ↘ RA , PA ->
  ⟦ tEq a b A ⟧ i , I ↘ R , P.
Proof. hauto lq:on ctrs:InterpExt. Qed.

Lemma InterpExt_Steps A0 A1 i I R P (rA : A0 ⇒* A1) :
  ⟦ A1 ⟧ i , I ↘ R , P -> ⟦ A0 ⟧ i , I ↘ R , P.
Proof.
  elim : A0 A1 /rA; auto.
  sfirstorder use:InterpExt_Step.
Qed.

(* InterpUnivN is symmetric *)

Lemma InterpExt_sym i I A R P
  (h : ⟦ A ⟧ i , I ↘ R , P)
  (ih : forall j lt A B, I j lt A B -> I j lt B A) :
  forall a b, R a b -> R b a.
Proof.
  elim : A R P /h => //;
  hauto lq:on unfold:ProdSpace, EqSpace.
Qed.

(* TODO: not the right theorem??
Lemma InterpExt_sym_P i I A B R P
  (h : ⟦ A ⟧ i , I ↘ R , P)
  (ih : forall j lt A B, I j lt A B -> I j lt B A) :
  P B -> ⟦ B ⟧ i , I ↘ R , P.
Proof.
  move : B. elim : A R P /h => //.
  - move => A B RA RF PA PF hA ihA hRF hPF hB ihB C [A'] [B'] [r] [hPA] hPB.
    eapply InterpExt_Steps; eauto.
    apply InterpExt_Fun; auto.
    move => *. eapply ihB; eauto.
    admit.
  - move => *. eapply InterpExt_Steps; eauto using InterpExt_Univ.
  - move => a b A R P hA ihA B [a'] [b'] [A'] [r] [hP] [hRa] hRb.
    eapply InterpExt_Steps; eauto.
    eapply InterpExt_Eq'.
    3: apply ihA; auto.
    * unfold EqSpace.
      fext. move => p1 p2.
      apply propositional_extensionality.
      intuition.
      admit. admit.
    * unfold EqType.
      fext. move => C.
      apply propositional_extensionality. split.
      + move => [a''] [b''] [A''] [r''] [hP'] [hRa'] hRb'.
        exists a'', b'', A''. repeat split; auto.
        admit. admit.
      + move => [a''] [b''] [A''] [r''] [hP'] [hRa'] hRb'.
        exists a'', b'', A''. repeat split; auto.
        admit. admit.
Admitted.
*)

Lemma InterpUnivN_sym i A R P (h : ⟦ A ⟧ i ↘ R , P) :
  forall a b, R a b -> R b a.
Proof.
  simp InterpUnivN in h.
  elim : A R P /h => //;
  hauto lq:on use:InterpExt_sym unfold:ProdSpace, EqSpace.
Qed.

(* Inversion lemmas *)

Lemma InterpExt_Fun_inv i I A B R P
  (h :  ⟦ tPi A B ⟧ i , I ↘ R, P) :
  exists (RA : tm_rel) (RF : tm -> tm_rel -> Prop) (PA : tm_set) (PF : tm -> tm_set -> Prop),
    ⟦ A ⟧ i , I ↘ RA , PA /\
    (forall a0 a1, RA a0 a1 -> exists RB, RF a0 RB /\ RF a1 RB) /\
    (forall a0 a1, RA a0 a1 -> exists PB, PF a0 PB /\ PF a1 PB) /\
    (forall a RB PB, RF a RB -> PF a PB -> ⟦ B[a..] ⟧ i , I ↘ RB , PB) /\
    R = ProdSpace RA RF /\ P = ProdType RA PA PF.
Proof.
  move E : (tPi A B) h => T h.
  move : A B E.
  elim : T R P / h => //.
  - hauto lq:on.
  - move => *; subst.
    hauto lq:on rew:off inv:Par ctrs:InterpExt use:Par_subst.
Qed.

Lemma InterpExt_Univ_inv i I R P j :
  ⟦ tUniv j ⟧ i , I ↘ R , P ->
  exists lt, R = I j lt /\ P = (fun A => A ⇒* tUniv j).
Proof.
  move E : (tUniv j) => A h.
  move : E.
  elim : A R P / h => //;
  hauto l:on inv:Par,tm.
Qed.

Lemma InterpUnivN_Univ_inv i j R P (h : ⟦ tUniv j ⟧ i ↘ R , P) :
  j < i /\
    (R = (fun A0 A1 => exists RA P0 P1,
      ⟦ A0 ⟧ j ↘ RA , P0 /\ ⟦ A1 ⟧ j ↘ RA , P1 /\ P0 A1 /\ P1 A0)) /\
    (P = (fun A => A ⇒* tUniv j)).
Proof.
  simp InterpUnivN in h.
  hauto l:on use:InterpExt_Univ_inv.
Qed.

(* Backward preservation *)

Lemma InterpExt_bwd_R i I A R P
  (h : ⟦ A ⟧ i , I ↘ R , P)
  (hI : forall j lt a0 a1 b0 b1,
        a0 ⇒ a1 -> b0 ⇒ b1 ->
        I j lt a1 b1 -> I j lt a0 b0) :
  forall a0 a1 b0 b1, a0 ⇒ a1 -> b0 ⇒ b1 -> R a1 b1 -> R a0 b0.
Proof.
  elim : A R P /h => //.
  - move => A B RA RF PA PF hA ihA hRF hPF hB ihB f0 f1 g0 g1 ra rb h a0 a1 RB hRA hRF0 hRF1.
    case /(_ a0 a1 hRA) : hPF => [PB] [hPF0] hPF1.
    qauto l:on use:P_App, Par_refl unfold:ProdSpace.  
  - hauto lq:on ctrs:rtc.
Qed.

Lemma InterpExt_bwds_R i I A R P
  (h : ⟦ A ⟧ i , I ↘ R , P)
  (hI : forall j lt a0 a1 b0 b1,
        a0 ⇒* a1 -> b0 ⇒* b1 ->
        I j lt a1 b1 -> I j lt a0 b0) :
  forall a0 a1 b0 b1, a0 ⇒* a1 -> b0 ⇒* b1 -> R a1 b1 -> R a0 b0.
Proof.
  move => a0 a1 + + ra.
  elim : a0 a1 /ra.
  1: move => a b0 b1 rb.
  2: move => a0 a1 a2 ra01 ra12 iha b0 b1 rb.
  all: elim : b0 b1 /rb => //.
  - move => b0 b1 b2 rb01 rb12 hRb1 hRb2.
    eapply InterpExt_bwd_R; eauto using Par_refl.
    move => *. eapply hI; eauto using rtc_once.
  - move => b hRa2.
    eapply InterpExt_bwd_R; eauto using Par_refl.
    move => *. eapply hI; eauto using rtc_once.
    sauto lq:on use:rtc_once.
  - move => b0 b1 b2 rb01 rb12 ihb hRb2.
    eapply InterpExt_bwd_R; eauto.
    move => *. eapply hI; eauto using rtc_once.
Qed.

Lemma InterpExt_bwd_P i I A R P
  (h : ⟦ A ⟧ i , I ↘ R , P) :
  forall B0 B1, B0 ⇒ B1 -> P B1 -> P B0.
Proof.
  elim : A R P /h => //;
  hauto lq:on ctrs:rtc unfold:ProdType, EqType.
Qed.

Lemma InterpExt_bwds_P i I A R P
  (h : ⟦ A ⟧ i , I ↘ R , P) :
  forall B0 B1, B0 ⇒* B1 -> P B1 -> P B0.
Proof.
  move => B0 B1 r.
  elim : B0 B1 /r => //.
  move => *. eapply InterpExt_bwd_P; eauto.
Qed.

Lemma InterpUnivN_bwds_R i A R P
  (h : ⟦ A ⟧ i ↘ R , P) :
  forall a0 a1 b0 b1, a0 ⇒* a1 -> b0 ⇒* b1 -> R a1 b1 -> R a0 b0.
Proof.
  simp InterpUnivN in h.
  eapply InterpExt_bwds_R; eauto.
  move => j lt a0 a1 b0 b1 ra rb [RA] [P0] [P1] [ha1] [hb1] [hP0] hP1.
  exists RA, P0, P1. simp InterpUnivN in *.
  hauto lq:on use:InterpExt_Steps, InterpExt_bwds_P.
Qed.

(* Forward preservation *)

Lemma InterpExt_fwds_R i I A R P a0 a1 b0 b1
  (h : ⟦ A ⟧ i , I ↘ R , P)
  (hI : forall j lt a0 a1 b0 b1,
        a0 ⇒* a1 -> b0 ⇒* b1 ->
        I j lt a0 b0 -> I j lt a1 b1)
  (ra : a0 ⇒* a1) (rb : b0 ⇒* b1) :
  R a0 b0 -> R a1 b1.
Proof.
  move : a0 a1 b0 b1 ra rb.
  elim : A R P /h => //.
  - move => ? ? ? ? ? ? _ _ _ hPF _ ihRB * a0 a1 ? hRA *.
    case /(_ a0 a1 hRA) : hPF => PB [hPF0] hPF1.
    eapply ihRB; eauto;
      last by hauto lq:on unfold:ProdSpace.
    all: hauto lq:on ctrs:rtc use:Pars_App.
  - move => > _ _ > rp rq [rpRefl0] [rqRefl0] RAab.
    have [p' [rpRefl1 rp1]] := Pars_confluent _ _ _ rpRefl0 rp.
    have [q' [rqRefl1 rq1]] := Pars_confluent _ _ _ rqRefl0 rq.
    sauto l:on use:Pars_refl_inv.
Qed.

Lemma InterpExt_fwds_P i I A R P B0 B1
  (h : ⟦ A ⟧ i , I ↘ R , P)
  (I_fwds : forall j lt a0 a1 b0 b1,
            a0 ⇒* a1 -> b0 ⇒* b1 ->
            I j lt a0 b0 -> I j lt a1 b1)
  (r : B0 ⇒* B1) :
  P B0 -> P B1.
Proof.
  move : B0 B1 r.
  elim : A R P /h => //.
  - move => A B RA RF PA PF hA ihA hRF hPF hB ihB B0 B1 r [A'] [B'] [r'] [hPA] hPB.
    have [C [rC rPiC]] := Pars_confluent _ _ _ r r'.
    move /Pars_pi_inv : rPiC => [A''] [B''] [E] [rA'] rB'. subst.
    exists A'', B''. split; auto; split. eapply ihA; eauto.
    move => a0 a1 PB hRA hPF0 hPF1.
    move /(_ a0 a1 PB hRA hPF0 hPF1) : hPB => [hPB0] hPB1.
    move /(_ a0 a1 hRA) : hRF => [RB] [hRF0] hRF1.
    hauto lq:on ctrs:rtc use:Par_subst_star.
  - move => j lt B0 B1 r1 rUniv.
    have [B2 [r12 rUniv2]] := Pars_confluent _ _ _ r1 rUniv.
    move /Pars_univ_inv : rUniv2 => <- //.
  - move => a b A R P h ih B0 B1 r [a'] [b'] [A'] [rEq] [hPA'] [hRa] hRb.
    have [B2 [r12 rEq2]] := Pars_confluent _ _ _ r rEq.
    move /Pars_eq_inv : rEq2 => [a''] [b''] [A''] [E] [ra] [rb] rA.
    hauto l:on ctrs:rtc use:InterpExt_fwds_R.
Qed.

Lemma InterpExt_fwds i I A B R P
  (I_bwd : forall j lt a0 a1 b0 b1,
           a0 ⇒* a1 -> b0 ⇒* b1 -> I j lt a1 b1 -> I j lt a0 b0)
  (I_fwd : forall j lt a0 a1 b0 b1,
           a0 ⇒* a1 -> b0 ⇒* b1 -> I j lt a0 b0 -> I j lt a1 b1)
  (r : A ⇒* B) :
  ⟦ A ⟧ i , I ↘ R , P ->
  ⟦ B ⟧ i , I ↘ R , P.
Proof.
  move => h. move : B r.
  elim : A R P /h.
  - hauto l:on use:Pars_pi_inv, InterpExt_Fun, Pars_morphing_star, rtc_refl.
  - hauto lq:on ctrs:InterpExt use:Pars_univ_inv.
  - move => > h ih T /Pars_eq_inv => [[a'] [b'] [A'] [->] [ra] [rb] rA].
    eapply InterpExt_Eq'; last by apply ih.
    + fext. move => *. apply propositional_extensionality.
      hauto l:on use:InterpExt_fwds_R, InterpExt_bwds_R.
    + fext. move => *. apply propositional_extensionality.
      hauto l:on use:InterpExt_fwds_R, InterpExt_bwds_R, rtc_refl.
  - move => A0 A1 RA PA rA01 hA1 ih A2 rA02.
    have [B3 [rA13 rA23]] := Pars_confluent _ _ _ (rtc_once _ _ rA01) rA02.
    eapply InterpExt_Steps; eauto.
Qed.

Lemma InterpUnivN_fwds_R i A R P a0 a1 b0 b1
  (h : ⟦ A ⟧ i ↘ R , P)
  (ra : a0 ⇒* a1) (rb : b0 ⇒* b1) :
  R a0 b0 -> R a1 b1.
Proof.
  move : A R a0 a1 b0 b1 h ra rb.
  have h : Acc (fun x y => x < y) i by sfirstorder use:wellfounded.
  elim : i /h.
  move => j ih h A R a0 a1 b0 b1 hA ra rb hR0.
  simp InterpUnivN in *.
  eapply InterpExt_fwds_R; eauto. simpl.
  move => i lt A0 A1 B0 B1 rA rB [RA] [P0] [P1] [hA0] [hB0] [hP0B0] hP1A0.
  exists RA, P0, P1. repeat split.
Admitted.

Lemma InterpUnivN_fwd i A B R (r : A ⇒ B) :
  ⟦ A ⟧ i ↘ R -> ⟦ B ⟧ i ↘ R.
Proof.
  move : A B R r.
  have h : Acc (fun x y => x < y) i by sfirstorder use:wellfounded.
  elim : i /h.
  hauto l:on ctrs:PerType use:InterpExt_fwd, PerTypeN_fwd, PerTypeN_nolt.
Qed.

Lemma InterpUnivN_fwds_R i A R a0 a1 b0 b1
  (h : ⟦ A ⟧ i ↘ R)
  (ra : a0 ⇒* a1) (rb : b0 ⇒* b1) :
  R a0 b0 -> R a1 b1.
Proof.
  elim : a0 a1 /ra; elim : b0 b1 /rb;
  hauto lq:on use:InterpUnivN_fwd_R, Par_refl.
Qed.

Lemma InterpUnivN_fwds i A B R (r : A ⇒* B) :
  ⟦ A ⟧ i ↘ R ->
  ⟦ B ⟧ i ↘ R.
Proof. elim : A B /r; hauto lq:on use:InterpUnivN_fwd. Qed.

Lemma PerTypeN_fwds i A0 A1 B0 B1 (rA : A0 ⇒* A1) (rB : B0 ⇒* B1) :
  ⟦ A0 ⟧ ~ ⟦ B0 ⟧ i -> ⟦ A1 ⟧ ~ ⟦ B1 ⟧ i.
Proof.
  elim : A0 A1 /rA; elim : B0 B1 /rB;
  hauto lq:on use:PerTypeN_fwd, Par_refl.
Qed.

(* Coherence preservation *)

Lemma InterpUnivN_coherent i A B R (r : A ⇔ B) :
  ⟦ A ⟧ i ↘ R -> ⟦ B ⟧ i ↘ R.
Proof.
  move => h. case : r => [C [rA rB]].
  eapply InterpExt_Steps; eauto. clear rB.
  eapply InterpUnivN_fwds; eauto.
Qed.

Lemma PerTypeN_coherent i A0 A1 B0 B1 (rA : A0 ⇔ A1) (rB : B0 ⇔ B1) :
  ⟦ A0 ⟧ ~ ⟦ B0 ⟧ i -> ⟦ A1 ⟧ ~ ⟦ B1 ⟧ i.
Proof.
  move => h.
  case : rA => [A [rA0 rA1]].
  case : rB => [B [rB0 rB1]].
  eapply PerTypeN_Steps; eauto. clear rA1 rB1.
  eapply PerTypeN_fwds; eauto.
Qed.

(* PerType_Fun inversion lemmas *)

Lemma PerType_Fun_inv i I A0 B0 T
  (h : ⟦ tPi A0 B0 ⟧ ~ ⟦ T ⟧ i , I) :
  exists A1 B1 RA,
    T ⇒* tPi A1 B1 /\
    ⟦ A0 ⟧ ~ ⟦ A1 ⟧ i , I /\
    ⟦ A0 ⟧ i , I ↘ RA /\
    ⟦ A1 ⟧ i , I ↘ RA /\
    (forall a0 a1, RA a0 a1 -> ⟦ B0[a0..] ⟧ ~ ⟦ B1[a1..] ⟧ i , I).
Proof.
  move E : (tPi A0 B0) h => T0 h.
  move : A0 B0 E.
  elim : T0 T /h => //.
  - sauto lq:on.
  - move => C0 C1 D0 D1 rC rD h ih A0 B0 E; subst.
    elim /Par_inv : rC => //.
    move => ? ? A1 ? B1 rA rB.
    case => ? ? ?; subst.
    case : (ih A1 B1) => // A2 [B2] [RA] [r] [hA] [hRA1] [hRA2] hB.
    exists A2, B2, RA. repeat split; auto.
    + eapply rtc_transitive; eauto using rtc_once.
    + eapply PerType_Step; eauto using Par_refl.
    + eapply InterpExt_Step; eauto.
    + qauto l:on use:PerType_Step, Par_subst, Par_refl.
Qed.

Lemma PerType_Fun_inv' i I A0 B0 A1 B1
  (h : ⟦ tPi A0 B0 ⟧ ~ ⟦ tPi A1 B1 ⟧ i , I) :
  exists RA,
    ⟦ A0 ⟧ ~ ⟦ A1 ⟧ i , I /\
    ⟦ A0 ⟧ i , I ↘ RA /\
    ⟦ A1 ⟧ i , I ↘ RA /\
    (forall a0 a1, RA a0 a1 -> ⟦ B0[a0..] ⟧ ~ ⟦ B1[a1..] ⟧ i , I).
Proof.
  move /PerType_Fun_inv : h => [A2] [B2] [RA] [r] [hA] [hRA0] [hRA2] hB.
  case /Pars_pi_inv : r => [A3] [B3] [E] [rA] rB. inversion E. subst.
  exists RA. repeat split; auto.
  - eapply PerType_Steps; eauto using rtc_refl.
  - eapply InterpExt_Steps; eauto.
  - hauto lq:on use:PerType_Steps, rtc_refl, Par_subst_star.
Qed.

Lemma PerTypeN_Fun_inv i A0 B0 T
  (h : ⟦ tPi A0 B0 ⟧ ~ ⟦ T ⟧ i) :
  exists A1 B1 RA,
    T ⇒* tPi A1 B1 /\
    ⟦ A0 ⟧ ~ ⟦ A1 ⟧ i /\
    ⟦ A0 ⟧ i ↘ RA /\
    ⟦ A1 ⟧ i ↘ RA /\
    (forall a0 a1, RA a0 a1 -> ⟦ B0[a0..] ⟧ ~ ⟦ B1[a1..] ⟧ i).
Proof. hauto lq:on use:PerTypeN_nolt, PerType_Fun_inv. Qed.

Lemma PerTypeN_Fun_inv' i A0 B0 A1 B1
  (h : ⟦ tPi A0 B0 ⟧ ~ ⟦ tPi A1 B1 ⟧ i) :
  exists RA,
    ⟦ A0 ⟧ ~ ⟦ A1 ⟧ i /\
    ⟦ A0 ⟧ i ↘ RA /\
    ⟦ A1 ⟧ i ↘ RA /\
    (forall a0 a1, RA a0 a1 -> ⟦ B0[a0..] ⟧ ~ ⟦ B1[a1..] ⟧ i).
Proof. hauto lq:on use:PerTypeN_nolt, PerType_Fun_inv'. Qed.

(* tEq inversion lemmas *)

Lemma InterpExt_Eq_inv i I a b A R
  (I_bwd : forall j lt a0 a1 b0 b1,
           a0 ⇒ a1 -> b0 ⇒ b1 -> I j lt a1 b1 -> I j lt a0 b0)
  (I_fwd : forall j lt a0 a1 b0 b1,
           a0 ⇒ a1 -> b0 ⇒ b1 -> I j lt a0 b0 -> I j lt a1 b1)
  (h : ⟦ tEq a b A ⟧ i , I ↘ R) :
  exists (RA : tm_rel),
    ⟦ A ⟧ i , I ↘ RA /\
    R = (fun p1 p2 => p1 ⇒* tRefl /\ p2 ⇒* tRefl /\ RA a b).
Proof.
  move E : (tEq a b A) h => T h.
  move : a b A E.
  elim : T R / h => //.
  - hauto lq:on.
  - move => T1 T2 R rT hR ih.
    elim /Par_inv : rT => //.
    move => rT a0 b0 A0 a1 b1 A1 ra rb rA E0 E1 a b A E.
    inversion E. subst.
    move /(_ a1 b1 A1 eq_refl) : ih => [RA [hRA ERA]].
    exists RA. split. eapply InterpExt_Step; eauto.
    fext. move => p1 p2. subst.
    apply propositional_extensionality. intuition.
    eapply InterpExt_bwd_R; eauto.
    eapply InterpExt_fwd_R; eauto.
Qed.

Lemma PerType_Eq_inv i I a0 b0 A0 T
  (I_bwd : forall j lt a0 a1 b0 b1,
           a0 ⇒ a1 -> b0 ⇒ b1 -> I j lt a1 b1 -> I j lt a0 b0)
  (I_fwd : forall j lt a0 a1 b0 b1,
           a0 ⇒ a1 -> b0 ⇒ b1 -> I j lt a0 b0 -> I j lt a1 b1)
  (h : ⟦ tEq a0 b0 A0 ⟧ ~ ⟦ T ⟧ i , I) :
  exists a1 b1 A1 RA,
    T ⇒* tEq a1 b1 A1 /\
    ⟦ A0 ⟧ ~ ⟦ A1 ⟧ i , I /\
    ⟦ A0 ⟧ i , I ↘ RA /\
    ⟦ A1 ⟧ i , I ↘ RA /\
    RA a0 a1 /\ RA b0 b1.
Proof.
  move E : (tEq a0 b0 A0) h => T0 h.
  move : a0 b0 A0 E.
  elim : T0 T /h => //.
  - hauto lq:on use:rtc_refl.
  - move => P0 P1 Q0 Q1 rP rQ h ih *. subst.
    elim /Par_inv : rP => //.
    hauto l:on ctrs:rtc use:PerType_Step, InterpExt_Step, InterpExt_bwd_R, Par_refl.
Qed.

Lemma InterpUnivN_Eq_inv i a b A R
  (h : ⟦ tEq a b A ⟧ i ↘ R) :
  exists (RA : tm_rel),
    ⟦ A ⟧ i ↘ RA /\
    R = (fun p1 p2 => p1 ⇒* tRefl /\ p2 ⇒* tRefl /\ RA a b).
Proof. hauto l:on use:InterpExt_Eq_inv, PerTypeN_Step, PerTypeN_fwd. Qed.

(* Zig zag *)

Lemma InterpExt_zigzag i I A B RA RB PA PB
  (hA : ⟦ A ⟧ i , I ↘ RA , PA)
  (hB : ⟦ B ⟧ i , I ↘ RB , PB)
  (I_bwd : forall j lt a0 a1 b0 b1,
           a0 ⇒* a1 -> b0 ⇒* b1 -> I j lt a1 b1 -> I j lt a0 b0)
  (I_fwd : forall j lt a0 a1 b0 b1,
           a0 ⇒* a1 -> b0 ⇒* b1 -> I j lt a0 b0 -> I j lt a1 b1) :
  PA B -> PB A.
Proof.
  elim : A RA PA /hA.
  - admit.
  - hauto lq:on use:InterpExt_fwds, InterpExt_Univ_inv, rtc_refl.
  - move => a b A R P hA ih [a'] [b'] [A'] [r] [hPA'] [hRa] hRb.
    eapply InterpExt_fwds in hB; eauto.
    admit.
Admitted.

(* Interpretations are cumulative *)

Lemma InterpUnivN_cumulative i j A RA :
  i <= j ->
  ⟦ A ⟧ i ↘ RA ->
  ⟦ A ⟧ j ↘ RA.
Proof.
  move => ij hi.
  elim : A RA /hi.
  2: sauto lq:on use:InterpExt_Univ', PeanoNat.Nat.le_trans, PerTypeN_nolt.
  all: hauto l:on ctrs:InterpExt use:PeanoNat.Nat.le_trans.
Qed.

Lemma PerTypeN_cumulative i j A B :
  i <= j ->
  ⟦ A ⟧ ~ ⟦ B ⟧ i ->
  ⟦ A ⟧ ~ ⟦ B ⟧ j.
Proof.
  simp PerTypeN. move => lt h. move : j lt.
  elim : A B /h;
  econstructor; eauto;
  hauto l:on use:InterpUnivN_cumulative, PeanoNat.Nat.le_trans.
Qed.

(* Interpretations are deterministic *)

Lemma InterpExt_deterministic i I A RA RB
  (I_bwd : forall j lt a0 a1 b0 b1,
           a0 ⇒ a1 -> b0 ⇒ b1 -> I j lt a1 b1 -> I j lt a0 b0)
  (I_fwd : forall j lt a0 a1 b0 b1,
           a0 ⇒ a1 -> b0 ⇒ b1 -> I j lt a0 b0 -> I j lt a1 b1) :
  ⟦ A ⟧ i , I ↘ RA ->
  ⟦ A ⟧ i , I ↘ RB ->
  RA = RB.
Proof.
  move => h.
  move : RB.
  elim : A RA / h.
  - move => A B RA RF _ ihRA hRF hRB ihRB R hR.
    move /InterpExt_Fun_inv : hR => [RA'] [RF'] [hRA'] [hRF'] [hRB'] ->.
    fext => b0 b1 a0 a1 RB'.
    apply propositional_extensionality.
    hauto lq:on rew:off finish:(assumption). (* slow *)
  - move => j lt RB /InterpExt_Univ_inv => [[lt'] ->].
    rewrite (Coq.Arith.Peano_dec.le_unique _ _ lt lt'). reflexivity.
  - move => *. fext. hauto lq:on use:InterpExt_Eq_inv.
  - sfirstorder use:InterpExt_fwd.
Qed.

Lemma InterpUnivN_deterministic i A RA RB :
  ⟦ A ⟧ i ↘ RA ->
  ⟦ A ⟧ i ↘ RB ->
  RA = RB.
Proof.
  apply InterpExt_deterministic.
  - sfirstorder use:PerTypeN_Step.
  - sfirstorder use:PerTypeN_fwd.
Qed.

Lemma InterpUnivN_deterministic' i j A RA RB :
  ⟦ A ⟧ i ↘ RA ->
  ⟦ A ⟧ j ↘ RB ->
  RA = RB.
Proof.
  move => hRA hRB.
  case : (Coq.Arith.Compare_dec.le_le_S_dec i j).
  - hauto l:on use:InterpUnivN_cumulative, InterpUnivN_deterministic.
  - move => ?. have : j <= i by lia.
    hauto l:on use:InterpUnivN_cumulative, InterpUnivN_deterministic.
Qed.

Lemma InterpUnivN_Fun'_inv i A B R
  (h : ⟦ tPi A B ⟧ i ↘ R) :
  exists (RA : tm_rel),
    ⟦ A ⟧ i ↘ RA /\
    (forall a0 a1, RA a0 a1 -> exists RB, ⟦ B[a0..] ⟧ i ↘ RB /\ ⟦ B[a1..] ⟧ i ↘ RB) /\
    R = ProdSpace RA (fun a RB => ⟦ B[a..] ⟧ i ↘ RB).
Proof.
  move /InterpExt_Fun_inv : h => [RA [RF [hRA [hRF [hRB ->]]]]].
  exists RA. repeat split => //.
  - hauto lq:on unfold:InterpUnivN.
  - fext => b0 b1 a0 a1 RB Ra.
    apply propositional_extensionality.
    split.
    + move : hRF Ra. move /[apply] => [[RB' [RF0 RF1]] RBba] hRB0 _.
      have hRB0' : ⟦ B[a0..] ⟧ i , (fun j _ => PerTypeN j) ↘ RB' by auto.
      have RBRB' : RB = RB' by eauto using InterpUnivN_deterministic.
      sfirstorder.
    + sfirstorder unfold:InterpUnivN.
Qed.

(* InterpUnivN and PerTypeN are transitive and reflexive *)

Lemma InterpExt_trans i I A R
  (h : ⟦ A ⟧ i , I ↘ R)
  (hsym : forall j lt A B, I j lt A B -> I j lt B A)
  (htrans : forall j lt A B C, I j lt A B -> I j lt B C -> I j lt A C) :
  forall a b c, R a b -> R b c -> R a c.
Proof.
  elim : A R /h;
  hauto l:on use:InterpExt_sym unfold:ProdSpace.
Qed.

Lemma InterpExt_refl i I A R
  (h : ⟦ A ⟧ i , I ↘ R)
  (hsym : forall j lt A B, I j lt A B -> I j lt B A)
  (htrans : forall j lt A B C, I j lt A B -> I j lt B C -> I j lt A C) :
  forall a b, R a b -> R a a /\ R b b.
Proof. hauto lq:on use:InterpExt_sym, InterpExt_trans. Qed.

Lemma PerType_trans i I
  (I_bwd : forall j lt a0 a1 b0 b1,
           a0 ⇒ a1 -> b0 ⇒ b1 -> I j lt a1 b1 -> I j lt a0 b0)
  (I_fwd : forall j lt a0 a1 b0 b1,
           a0 ⇒ a1 -> b0 ⇒ b1 -> I j lt a0 b0 -> I j lt a1 b1)
  (hsym : forall A B, (⟦ A ⟧ ~ ⟦ B ⟧ i , I) -> (⟦ B ⟧ ~ ⟦ A ⟧ i , I))
  (Isym : forall j lt A B, I j lt A B -> I j lt B A)
  (Itrans : forall j lt A B C, I j lt A B -> I j lt B C -> I j lt A C) :
  forall A B C, (⟦ A ⟧ ~ ⟦ B ⟧ i , I) -> (⟦ B ⟧ ~ ⟦ C ⟧ i , I) -> (⟦ A ⟧ ~ ⟦ C ⟧ i , I).
Proof.
  move => A B C h. move : C.
  elim : A B /h.
  - move => A0 A1 B0 B1 RA hA01 ihA hRA0 hRA1 hB01 ihB C.
    move /PerType_Fun_inv => [A2] [B2] [RA'] [hC] [hA12] [hRA1'] [hRA2'] hB12.
    have E : RA = RA' by eapply InterpExt_deterministic; eauto. subst.
    hauto lq:on ctrs:PerType use:PerType_Steps, rtc_refl, InterpExt_refl.
  - sfirstorder.
  - move => a0 a1 b0 b1 A0 A1 RA hA ihA01 hRA0 hRA1 RAa RAb C.
    move /(PerType_Eq_inv i I a1 b1 A1 C I_bwd I_fwd) =>
      [a2] [b2] [A2] [RA'] [rC] [hA12] [hRA1'] [hRA2'] [RAa'] RAb'.
    have E : RA = RA' by eapply InterpExt_deterministic; eauto. subst.
    hauto l:on use:PerType_Steps, rtc_refl, PerType_Eq, InterpExt_trans.
  - hauto lq:on ctrs:PerType use:Par_refl, PerType_fwd.
Qed.

Lemma PerTypeN_trans i : forall A B C,
  PerTypeN i A B -> PerTypeN i B C -> PerTypeN i A C.
Proof.
  have h : Acc (fun x y => x < y) i by sfirstorder use:wellfounded.
  elim : i /h.
  move => j h ih A B C hAB hBC.
  rewrite PerTypeN_nolt.
  apply PerType_trans with (B := B);
  try rewrite <- PerTypeN_nolt;
  eauto using PerTypeN_Step, PerTypeN_fwd, PerTypeN_sym.
Qed.

Lemma InterpUnivN_trans i A R (h : ⟦ A ⟧ i ↘ R) :
  forall a b c, R a b -> R b c -> R a c.
Proof.
  elim : A R /h;
  hauto l:on use:InterpExt_sym, PerTypeN_sym, PerTypeN_trans unfold:ProdSpace.
Qed.

Lemma InterpUnivN_refl i A R (h : ⟦ A ⟧ i ↘ R) :
  forall a b, R a b -> R a a /\ R b b.
Proof. hauto lq:on use:InterpUnivN_sym, InterpUnivN_trans. Qed.

Lemma PerTypeN_refl i : forall A B, ⟦ A ⟧ ~ ⟦ B ⟧ i ->
  ⟦ A ⟧ ~ ⟦ A ⟧ i /\ ⟦ B ⟧ ~ ⟦ B ⟧ i.
Proof. hauto lq:on use:PerTypeN_sym, PerTypeN_trans. Qed.

(* Related types have common interpretations *)

Lemma PerType_InterpExt i I A B
  (h : ⟦ A ⟧ ~ ⟦ B ⟧ i , I)
  (I_bwd : forall j lt a0 a1 b0 b1,
           a0 ⇒ a1 -> b0 ⇒ b1 -> I j lt a1 b1 -> I j lt a0 b0)
  (I_fwd : forall j lt a0 a1 b0 b1,
           a0 ⇒ a1 -> b0 ⇒ b1 -> I j lt a0 b0 -> I j lt a1 b1)
  (Isym : forall j lt A B, I j lt A B -> I j lt B A)
  (Itrans : forall j lt A B C, I j lt A B -> I j lt B C -> I j lt A C) :
  exists R, ⟦ A ⟧ i , I ↘ R /\ ⟦ B ⟧ i , I ↘ R.
Proof.
  elim : A B /h.
  - move => A0 A1 B0 B1 RA hA ihA hRA0 hRA1 hB ihB.
    eexists. split;
    eapply InterpExt_Fun with (RF := fun a RB => ⟦ B0[a..] ⟧ i , I ↘ RB /\ ⟦ B1[a..] ⟧ i , I ↘ RB); eauto.
    + move => a0 a1 hRA01.
      have hRA11 : RA a1 a1 by eapply InterpExt_refl; eauto.
      have hRA10 : RA a1 a0 by eapply InterpExt_sym; eauto.
      case : (ihB a0 a1 hRA01) => // R01 [hR00] hR11.
      case : (ihB a1 a1 hRA11) => // R11 [hR01] hR11'.
      case : (ihB a1 a0 hRA10) => // R10 [hR01'] hR10.
      have E0 : R01 = R11 by apply (InterpExt_deterministic _ _ _ _ _ I_bwd I_fwd hR11 hR11').
      have E1 : R11 = R10 by apply (InterpExt_deterministic _ _ _ _ _ I_bwd I_fwd hR01 hR01').
      hauto lq:on.
    + sfirstorder.
    + move => a0 a1 hRA01.
      have hRA11 : RA a1 a1 by eapply InterpExt_refl; eauto.
      have hRA10 : RA a1 a0 by eapply InterpExt_sym; eauto.
      case : (ihB a0 a1 hRA01) => // R01 [hR00] hR11.
      case : (ihB a1 a1 hRA11) => // R11 [hR01] hR11'.
      case : (ihB a1 a0 hRA10) => // R10 [hR01'] hR10.
      have E0 : R01 = R11 by apply (InterpExt_deterministic _ _ _ _ _ I_bwd I_fwd hR11 hR11').
      have E1 : R11 = R10 by apply (InterpExt_deterministic _ _ _ _ _ I_bwd I_fwd hR01 hR01').
      hauto lq:on.
    + sfirstorder.
  - hauto lq:on ctrs:InterpExt.
  - move => a0 a1 b0 b1 A0 A1 RA hA ihA hRA0 hRA1 RAa RAb.
    have RAsym := InterpExt_sym i I A0 RA hRA0 Isym.
    have RAtrans := InterpExt_trans i I A0 RA hRA0 Isym Itrans.
    have E : RA a0 b0 = RA a1 b1 by
      hauto lq:on use:propositional_extensionality.
    eexists. sauto lq:on use:InterpExt_Eq'.
  - hauto lq:on ctrs:InterpExt.
Qed.

Lemma PerTypeN_InterpUnivN i A B
  (h : ⟦ A ⟧ ~ ⟦ B ⟧ i) :
  exists R, ⟦ A ⟧ i ↘ R /\ ⟦ B ⟧ i ↘ R.
Proof.
  simp PerTypeN in h.
  qauto l:on unfold:InterpUnivN use:
    PerType_InterpExt, PerTypeN_nolt,
    PerTypeN_fwd, PerTypeN_Step,
    PerTypeN_sym, PerTypeN_trans.
Qed.

(* Soundness *)

Require Import typing.

Definition ρ_ok Γ ρ0 ρ1 := forall i A, lookup i Γ A ->
  forall m RA, ⟦ A[ρ0] ⟧ ~ ⟦ A[ρ1] ⟧ m ->
    ⟦ A[ρ0] ⟧ m ↘ RA -> ⟦ A [ρ1] ⟧ m ↘ RA ->
    RA (ρ0 i) (ρ1 i).

Definition SemWt Γ a A := forall ρ0 ρ1, ρ_ok Γ ρ0 ρ1 ->
  exists m RA, (⟦ A[ρ0] ⟧ ~ ⟦ A[ρ1] ⟧ m) /\
    (⟦ A [ρ0] ⟧ m ↘ RA) /\ (⟦ A [ρ1] ⟧ m ↘ RA) /\
    RA (a [ρ0]) (a [ρ1]).
Notation "Γ ⊨ a ∈ A" := (SemWt Γ a A) (at level 70).

Definition SemWff Γ := forall i A, lookup i Γ A -> exists j, Γ ⊨ A ∈ tUniv j.
Notation "⊨ Γ" := (SemWff Γ) (at level 70).

Lemma ρ_ok_nil ρ0 ρ1 : ρ_ok nil ρ0 ρ1.
Proof. rewrite /ρ_ok. inversion 1; subst. Qed.

Lemma ρ_ok_cons i Γ ρ0 ρ1 a0 a1 RA A :
  ⟦ A [ρ0] ⟧ i ↘ RA -> ⟦ A [ρ1] ⟧ i ↘ RA -> RA a0 a1 ->
  ρ_ok Γ ρ0 ρ1 ->
  ρ_ok (A :: Γ) (a0 .: ρ0) (a1 .: ρ1).
Proof.
  move => h0 h1 hR hρ.
  rewrite /ρ_ok. inversion 1; subst.
  - move => j RA' hA h0' h1'.
    asimpl in hA. asimpl in h0'. asimpl in h1'.
    suff : RA = RA' by congruence.
    hauto l:on drew:off use:InterpUnivN_deterministic'.
  - asimpl. hauto lq:on unfold:ρ_ok solve+:lia.
Qed.

Lemma ρ_ok_renaming Γ ρ0 ρ1 :
  forall Δ ξ,
    lookup_good_renaming ξ Γ Δ ->
    ρ_ok Δ ρ0 ρ1 ->
    ρ_ok Γ (ξ >> ρ0) (ξ >> ρ1).
Proof.
  move => Δ ξ hscope h1.
  rewrite /ρ_ok => i A hi j RA.
  move: (hscope _ _ hi) => ld.
  move: (h1 _ _ ld j RA).
  by asimpl.
Qed.

Lemma renaming_SemWt Γ a A :
  (Γ ⊨ a ∈ A) ->
  forall Δ ξ,
    lookup_good_renaming ξ Γ Δ ->
    Δ ⊨ a⟨ξ⟩ ∈ A⟨ξ⟩ .
Proof.
  rewrite /SemWt => h Δ ξ hξ ρ0 ρ1 hρ.
  have hρ' : (ρ_ok Γ (ξ >> ρ0) (ξ >> ρ1)) by eauto using ρ_ok_renaming.
  case /(_ _ _ hρ') : h => m [RA hRA].
  exists m, RA. by asimpl.
Qed.

Lemma weakening_Sem Γ a A B i
  (h0 : Γ ⊨ B ∈ tUniv i)
  (h1 : Γ ⊨ a ∈ A) :
   B :: Γ ⊨ a⟨S⟩ ∈ A⟨S⟩.
Proof.
  apply : renaming_SemWt; eauto.
  hauto lq:on ctrs:lookup unfold:lookup_good_renaming.
Qed.

Lemma SemWt_Univ Γ A i :
  (Γ ⊨ A ∈ tUniv i) <->
  forall ρ0 ρ1, ρ_ok Γ ρ0 ρ1 -> ⟦ A[ρ0] ⟧ ~ ⟦ A[ρ1] ⟧ i.
Proof.
  rewrite /SemWt.
  split.
  - hauto lq:on rew:off use:InterpUnivN_Univ_inv.
  - move => /[swap] ρ0 /[swap] ρ1 /[apply] h.
    exists (S i). exists (PerTypeN i).
    have ? : i < S i by lia. 
    repeat split; auto. simp PerTypeN.
    all: hauto lq:on unfold:InterpUnivN ctrs:PerType use:InterpExt_Univ'.
Qed.

Lemma SemWff_nil : SemWff nil. inversion 1. Qed.

Lemma SemWff_cons Γ A i :
  ⊨ Γ ->
  Γ ⊨ A ∈ tUniv i ->
  (* ------------ *)
  ⊨ A :: Γ.
Proof.
  move => wf wt k hscope.
  elim/lookup_inv.
  - hauto q:on use:weakening_Sem.
  - move => _ n B ? ? + ? []*. subst. move /wf => [j ?].
    exists j. change (tUniv j) with (tUniv j) ⟨S⟩.
    eauto using weakening_Sem.
Qed.

Theorem soundness :
  (forall Γ a A, Γ ⊢ a ∈ A -> Γ ⊨ a ∈ A) /\
  (forall Γ, ⊢ Γ -> ⊨ Γ).
Proof.
  apply wt_mutual.
  (* Var *)
  1: { 
    move => Γ i A _ wf hscope ρ0 ρ1 hρ.
    case /(_ _ _ hscope) : wf => j hA.
    move /SemWt_Univ : hA => /(_ ρ0 ρ1 hρ) hA.
    have [R [hRA0 hRA1]] := PerTypeN_InterpUnivN _ _ _ hA.
    move /(_ _ _ hscope j R) : hρ => /(_ hA hRA0 hRA1) hRρ.
    exists j, R. repeat split; auto.
  }
  (* Pi *)
  1: {
    move => Γ i A B hA /SemWt_Univ ihA hB /SemWt_Univ ihB ρ0 ρ1 hρ.
    specialize (ihA ρ0 ρ1 hρ).
    exists (S i). exists (PerTypeN i).
    repeat split.
    - apply PerTypeN_Univ. lia.
    - apply InterpExt_Univ'; auto.
    - apply InterpExt_Univ'; auto.
    - have [R [hRA0 hRA1]] := PerTypeN_InterpUnivN _ _ _ ihA.
      asimpl. eapply PerTypeN_Fun; eauto.
      move => a0 a1 hR. asimpl.
      hauto lq:on use:ρ_ok_cons.
  }
  (* Abs *)
  1: {
    move => Γ A b B i _ ihPi _ ihb ρ0 ρ1 hρ.
    case : (ihPi ρ0 ρ1 hρ) => // k [R] [_] [hR] [_] /ltac:(asimpl) hRPi.
    case /InterpUnivN_Univ_inv : hR => E /ltac:(subst) _. clear k ihPi.
    have [R [hR0 hR1]] := PerTypeN_InterpUnivN _ _ _ hRPi.
    exists i, R. repeat split; auto.
    case /InterpUnivN_Fun'_inv : hR0 => RA [hRA] [_] ->.
    move => a0 a1 RB' hRAa /ltac:(asimpl) hRB0' hRB1'.
    have hρa : ρ_ok (A :: Γ) (a0 .: ρ0) (a1 .: ρ1). {
      have [_ [hA _]] := PerTypeN_Fun_inv' _ _ _ _ _ hRPi.
      case /PerTypeN_InterpUnivN : hA => [RA'] [?] ?.
      have ERA : RA = RA' by eapply InterpUnivN_deterministic; eauto. subst.
      eapply ρ_ok_cons; eauto.
    }
    case /(_ (a0 .: ρ0) (a1 .: ρ1) hρa) : ihb => j [RB] [hB] [hRB0] [hRB1] hRBb.
    have <- : RB = RB' by hauto l:on use:InterpUnivN_deterministic'.
    clear R hRPi hR1 hRA hRAa RA hρ hρa RB' hB hRB0' hRB1' i.
    eapply InterpUnivN_bwd_R; eauto;
    eapply P_AppAbs'; auto using Par_refl; by asimpl.
  }
  (* App *)
  1: {
    move => Γ f A B a _ ihf _ iha ρ0 ρ1 hρ.
    case /(_ ρ0 ρ1 hρ) : iha => i [RA] [_] [hRA0] [hRA1] hRAa.
    case /(_ ρ0 ρ1 hρ) : ihf => /ltac:(asimpl) j [R] [hPi] [hR0] [hR1] hRf.
    case /InterpUnivN_Fun'_inv : hR0 => RA0 [hRA0'] [hRB0] E.
    case /InterpUnivN_Fun'_inv : hR1 => RA1 [hRA1'] [_] _.
    subst. unfold ProdSpace in hRf.
    case /PerTypeN_Fun_inv' : hPi => RA'' [_] [hRA0''] [hRA1''] hB.
    have ERA0 : RA0 = RA by hauto l:on use:InterpUnivN_deterministic'.
    have ERA1 : RA1 = RA by hauto l:on use:InterpUnivN_deterministic'.
    have ERA'' : RA'' = RA by hauto l:on use:InterpUnivN_deterministic'.
    subst. clear hRA0 hRA0' hRA0'' hRA1 hRA1' hRA1'' hρ i.
    move /(_ _ _ hRAa) : hB => hB.
    move /(_ _ _ hRAa) : hRB0 => [RB0] [hRB0'] hRB01.
    have [RB [hRB0 hRB1]] := PerTypeN_InterpUnivN _ _ _ hB.
    have ERB0 : RB0 = RB by hauto l:on use:InterpUnivN_deterministic.
    subst. move /(_ _ _ RB hRAa hRB0 hRB01) : hRf => hRBfa.
    asimpl in *. exists j, RB. repeat split; auto.
  }
  (* Conv (ew, subtyping...) *)
  1: {
    move => Γ a A B i _ iha _ ihB hsub ρ0 ρ1 hρ.
    case /(_ ρ0 ρ1 hρ) : iha => j [R] [hA] [hR1] [hR2] hRa.
    exists j, R. repeat split; auto; admit.
    (* best use:Coherent_subst_star, InterpUnivN_coherent, PerTypeN_coherent. *)
  }
  (* Univ *)
  5: hauto lq:on use:SemWt_Univ, PerTypeN_Univ.
  (* Refl *)
  5: {
    move => Γ a A _ wf _ iha ρ0 ρ1 hρ. asimpl.
    case /(_ ρ0 ρ1 hρ) : iha => i [R] [hA] [hRA0] [hRA1] hRAa.
    have E0 : R a[ρ0] a[ρ1] = R a[ρ0] a[ρ0] by
      hauto l:on use:propositional_extensionality, InterpUnivN_refl.
    have E1 : R a[ρ0] a[ρ1] = R a[ρ1] a[ρ1] by
      hauto l:on use:propositional_extensionality, InterpUnivN_refl.
    exists i, (fun p1 p2 => p1 ⇒* tRefl /\ p2 ⇒* tRefl /\ R a[ρ0] a[ρ1]).
    sauto lqb:on use:rtc_refl, PerTypeN_Eq, InterpExt_Eq'.
  }
  (* Eq *)
  5: {
    move => Γ a b A i _ iha _ ihb _ /SemWt_Univ ihA ρ0 ρ1 hρ.
    case /(_ ρ0 ρ1 hρ) : iha => j [RA0] [_] [hRA00] [hRA10] ?.
    case /(_ ρ0 ρ1 hρ) : ihb => k [RA1] [_] [hRA01] [hRA11] ?.
    move /(_ ρ0 ρ1 hρ) : ihA => ihA.
    case : (PerTypeN_InterpUnivN _ _ _ ihA) => [RA] [?] ?.
    have E0 : RA = RA0 by eapply InterpUnivN_deterministic'; eauto.
    have E1 : RA = RA1 by eapply InterpUnivN_deterministic'; eauto.
    subst. asimpl in *. clear hRA00 hRA10 hRA01 hRA11.
    exists (S i), (PerTypeN i).
    sauto l:on use:PerTypeN_Univ, InterpExt_Univ', PerTypeN_Eq.
  }
  (* J *)
  5: {
    move => Γ t a b p A i j C _ _ _ ihb _ _ _ ihp _ /SemWt_Univ ihC _ iht ρ0 ρ1 hρ.
    case /(_ ρ0 ρ1 hρ) : ihb => kb [RA] [_] [hRA0] [hRA1] hRAb.
    case /(_ ρ0 ρ1 hρ) : ihp => kp [REq] [_] [hREq0] [hREq1] hREqp.
    case /(_ ρ0 ρ1 hρ) : iht => kt [R] [_] [hR0] [_] hRt.
    asimpl in *.
    move /(InterpUnivN_Eq_inv _ _ _ _ _) : hREq0 => [RA0] [hRA0'] E0.
    move /(InterpUnivN_Eq_inv _ _ _ _ _) : hREq1 => [RA1] [hRA1'] E1.
    have ? : RA0 = RA by hauto l:on use:InterpUnivN_deterministic'. clear hRA0'.
    have ? : RA1 = RA by hauto l:on use:InterpUnivN_deterministic'. clear hRA1'.
    subst. move : hREqp => [rp0] [rp1] hRAab.
    have hρRefl : ρ_ok (tEq a ⟨S⟩ (var_tm 0) A ⟨S⟩ :: A :: Γ)
                    (tRefl[ρ0] .: (a[ρ0] .: ρ0))
                    (p[ρ1] .: (b[ρ1] .: ρ1)). {
      eapply ρ_ok_cons; asimpl; eauto.
      - eapply InterpExt_Eq' with
        (R := fun p0 p1 => p0 ⇒* tRefl /\ p1 ⇒* tRefl /\ RA a[ρ0] b[ρ0]); eauto.
        fext => *. apply propositional_extensionality. split;
        hauto lq:on use:InterpUnivN_refl.
      - eapply InterpExt_Eq'; eauto.
      - hauto lq:on use:rtc_refl, InterpUnivN_refl.
      - hauto lq:on use:ρ_ok_cons, InterpUnivN_trans.
    }
    have hρp : ρ_ok (tEq a ⟨S⟩ (var_tm 0) A ⟨S⟩ :: A :: Γ)
                    (p[ρ0] .: (b[ρ0] .: ρ0))
                    (p[ρ1] .: (b[ρ1] .: ρ1)). {
      eapply ρ_ok_cons; asimpl.
      1-3: sauto lq:on use:InterpExt_Eq'.
      eapply ρ_ok_cons; eauto.
    }
    clear hRA0 hRA1 E1.
    move /(ihC _ _) : hρRefl => hCRefl.
    move /(ihC _ _) : hρp => hCp. clear ihC.
    case /(PerTypeN_InterpUnivN _ _ _) : hCRefl => [RRefl] [hRRefl] hRp1'.
    case : (PerTypeN_InterpUnivN _ _ _ hCp) => [Rp] [hRp0] hRp1.
    have ? : RRefl = Rp by hauto l:on use:InterpUnivN_deterministic'. clear hRp1'.
    have ? : Rp = R by hauto l:on use:InterpUnivN_deterministic'. clear hR0 hRRefl.
    subst. exists i, R. repeat split; auto.
    eapply InterpUnivN_bwds_R with (a1 := t[ρ0]) (b1 := t[ρ1]);
    eauto using P_JRefl_star.
  }
  (* Nil *)
  8: apply SemWff_nil.
  (* Cons *)
  8: eauto using SemWff_cons.
  (* skip the rest *)
  all: admit.
Admitted.