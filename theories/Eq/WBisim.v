(*|
=========================================
Strong and Weak Bisimulations over ctrees
=========================================
The [equ] relation provides [ctree]s with a suitable notion of equality.
It is however much too fine to properly capture any notion of behavioral
equivalence that we could want to capture over computations modelled as
[ctree]s.
If we draw a parallel with [itree]s, [equ] maps directly to [eq_itree],
while [eutt] was introduced to characterize computations that exhibit the
same external observations, but may disagree finitely on the amount of
internal steps occuring between any two observations.
While the only consideration over [itree]s was to be insensitive to the
amount of fuel needed to run, things are richer over [ctree]s.
We essentially want to capture three intuitive things:
- to be insensitive to the particular branches chosen at non-deterministic
nodes -- in particular, we want [br t u ~~ br u t];
- to always be insensitive to how many _invisible_ br nodes are crawled
through -- they really are a generalization of [Tau] in [itree]s;
- to have the flexibility to be sensible or not to the amount of _visible_
br nodes encountered -- they really are a generalization of CCS's tau
steps. This last fact, whether we observe or not these nodes, will constrain
the distinction between the weak and strong bisimulations we define.

In contrast with [equ], as well as the relations in [itree]s, we do not
define the functions generating the relations directly structurally on
the trees. Instead, we follow a definition closely following the style
developed for process calculi, essentially stating that diagrams of this
shape can be closed.
t  R  u
|     |
l     l
v     v
t' R  u'
The transition relations that we use to this end are defined in the [Trans]
module:
- strong bisimulation is defined as a symmetric games over [trans];
- weak bisimulation is defined as an asymmetric game in which [trans] get
answered by [wtrans].

.. coq::none
|*)
From Coinduction Require Import
     coinduction rel tactics.

From ITree Require Import Core.Subevent.

From CTree Require Import
     CTree
     Eq.Equ
     Eq.Shallow
     Eq.Trans
     Eq.SSim
     Eq.SBisim.

From RelationAlgebra Require Export
     rel srel monoid kat kat_tac rewriting normalisation.

Import CTree.
Import CTreeNotations.
Import EquNotations.
Import SBisimNotations.

(*|
Weak Bisimulation
-------------------
Relation relaxing [equ] to become insensible to:
- the amount of (any kind of) brs taken;
- the particular branches taken during (any kind of) brs.
|*)

Section WeakBisim.

  Context {E C : Type -> Type} {X : Type} `{HasTau : B0 -< C}.
  Notation S := (ctree E C X).

  (*|
  The function defining weak simulations: [trans] plays must be answered
  using [wtrans].
  The [ws] definition stands for [weak simulation]. The bisimulation [wb]
  is once again obtained by expliciting the symmetric aspect of the definition.
  |*)
  Program Definition ws: mon (rel S S) :=
    {| body R p q :=
      forall l p', trans l p p' -> exists2 q', wtrans l q q' & R p' q' |}.
  Next Obligation. destruct (H0 _ _ H1). eauto. Qed.

  (*| Heterogenous version TODO: make ws |*)
  Program Definition hws {E F C D: Type -> Type} {X Y: Type} `{Stuck: B0 -< C} `{Stuck': B0 -< D}
          (L: rel (@label E) (@label F)) : mon (rel (ctree E C X) (ctree F D Y)) :=
    {| body R p q :=
      forall l p', trans l p p' -> exists q' l', wtrans l' q q' /\ R p' q' /\ L l l' |}.
  Next Obligation.
    destruct (H0 _ _ H1) as (? & ? & ? & ? & ?).
    do 2 eexists; intuition; eauto.
  Qed.

  (*|
    The bisimulation is obtained by intersecting [ws] with its symmetrized version.
    |*)
  Definition wb := (Coinduction.lattice.cap ws (comp converse (comp ws converse))).

  (*| Heterogenous version TODO: make wb |*)
  Program Definition hwb {E F C D: Type -> Type} {X Y: Type} `{Stuck: B0 -< C} `{Stuck': B0 -< D}
          (L: rel (@label E) (@label F)) : mon (rel (ctree E C X) (ctree F D Y)) :=
    {| body R p q :=
      hws L R p q /\ hws (flip L) (flip R) q p
    |}.
  Next Obligation.
    split; intros.
    - destruct (H0 _ _ H2) as (? & ? & ? & ? & ?).
      do 2 eexists; intuition; eauto.
    - destruct (H1 _ _ H2) as (? & ? & ? & ? & ?).
      do 2 eexists; intuition; eauto.
  Qed.

  (*|
    The function defining one-sided expansion (standard notion in process algebra).
    This relation echoes [euttge] over [itrees]: the amount of fuel required on either
    side of the computation can only decrease from left to right, not the other way around.
    We are not interested in this relation by itself, but it is an important proof intermediate.
    |*)

  Program Definition es: mon (rel S S) :=
    {| body R p q :=
      forall l p', trans l p p' -> exists2 q', etrans l q q' & R p' q' |}.
  Next Obligation. destruct (H0 _ _ H1). eauto. Qed.

  (*| Heterogenous version TODO: make es |*)
  Program Definition hes {E F C D: Type -> Type} {X Y: Type} `{Stuck: B0 -< C} `{Stuck': B0 -< D}
          (L: rel (@label E) (@label F)) : mon (rel (ctree E C X) (ctree F D Y)) :=
    {| body R p q :=
      forall l p', trans l p p' -> exists q' l', etrans l' q q' /\ R p' q' /\ L l l' |}.
  Next Obligation.
    destruct (H0 _ _ H1) as (? & ? & ? & ? & ?).
    do 2 eexists; intuition; eauto.
  Qed.

End WeakBisim.

(*|
The relation itself
|*)
Definition wbisim {E C X} `{HasStuck : B0 -< C} := (gfp (@wb E C X _): hrel _ _).

Module WBisimNotations.

  Notation "p ≈ q" := (wbisim p q) (at level 70).
  Notation wt := (coinduction.t wb).
  Notation wT := (coinduction.T wb).
  Notation wbt := (coinduction.bt wb).
  (*|
    Notations  for easing readability in proofs by enhanced coinduction
    |*)
  Notation "x [≈] y" := (wt _ x y) (at level 80).
  Notation "x {≈} y" := (wbt _ x y) (at level 80).
  Notation "t {{≈}} u" := (wb _ t u) (at level 79).

End WBisimNotations.

Import WBisimNotations.

Ltac fold_wbisim :=
  repeat
    match goal with
    | h: context[@wb ?E ?C ?X ?HS ] |- _ => fold (@wbisim E C X HS) in h
    | |- context[@wb ?E ?C ?X ?HS ]      => fold (@wbisim E C X HS)
    end.

Ltac __coinduction_wbisim R H :=
  unfold wbisim; apply_coinduction; fold_wbisim; intros R H.

Tactic Notation "__step_wbisim" :=
  match goal with
  | |- context[@wbisim ?E ?C ?X ?HasStuck ] =>
      unfold wbisim;
      step;
      fold (@wbisim E C X HasStuck)
  | |- _ => step
  end.

#[local] Tactic Notation "step" := __step_wbisim.

#[local] Tactic Notation "coinduction" simple_intropattern(R) simple_intropattern(H) :=
  __coinduction_wbisim R H.

Ltac __step_in_wbisim H :=
  match type of H with
  | context [@wbisim ?E ?C ?X ?HasStuck ] =>
      unfold wbisim in H;
      step in H;
      fold (@wbisim E C X HasStuck) in H
  end.

#[local] Tactic Notation "step" "in" ident(H) := __step_in_wbisim H.

Ltac twplayL_ tac :=
  match goal with
  | h : @wbisim ?E ?C ?X _ _ _ |- _ =>
      step in h;
      let Hf := fresh "Hf" in
      destruct h as [Hf _];
      cbn in Hf; edestruct Hf as [? ?TR ?EQ];
      [tac | clear Hf]
  end.

Tactic Notation "twplayL" tactic(t) := twplayL_ t.
Ltac wplayL H := twplayL ltac:(apply @H).
Ltac ewplayL := twplayL etrans.

Ltac twplayR_ tac :=
  match goal with
  | h : @wbisim ?E ?F ?C ?D ?X ?Y _ _ ?L |- _ =>
      step in h;
      let Hb := fresh "Hb" in
      destruct h as [_ Hb];
      cbn in Hb; edestruct Hb as [? ?TR ?EQ];
      [tac | clear Hb]
  end.

Tactic Notation "twplayR" tactic(t) := twplayR_ t.
Ltac wplayR H := twplayR ltac:(apply @H).
Ltac ewplayR := twplayR etrans.

Section wbisim_theory.

  Context {E C : Type -> Type} {X : Type} `{HasStuck : B0 -< C}.
  Notation ws := (@ws E C X HasStuck).
  Notation wb := (@wb E C X HasStuck).
  Notation wbisim  := (@wbisim E C X HasStuck).
  Notation wt  := (coinduction.t wb).
  Notation wbt := (coinduction.bt wb).
  Notation wT  := (coinduction.T wb).

(*|
Elementary properties of [wbisim]
----------------------------------------------
We have in short:
- [ss ≤ es ≤ ws] (direct consequence of transition relations' properties)
- [sbisim] ⊆ [wbisim]
- [equ] ⊆ [wbisim]
- [wbisim] is closed under [equ]
- [wbisim] is closed under [bisim]
- up-to reflexivity
- up-to symmetry
- transitivity (but NOT up-to transitivity)

We naturally also have [equ] ⊆ [sbisim], and hence [equ] ⊆  [wbisim], but we need
to work a bit more to establish it.
It is a consequence more generally of [sbisim] and [wbisim] being closed under [equ]
on both arguments.
We also get [wbisim] closed under [sbism] on both arguments, but need first to
establish [wbisim]'s transitivity for that.
|*)
  Lemma s_e: @ss E E C C X X _ _ eq  <= es.
  Proof.
    intros R p q H l p' pp'. destruct (H _ _ pp').
    destruct H0 as (? & ? & ? & <-).
    eexists; intuition; eauto using trans_etrans_.
  Qed.

  Lemma e_w: es <= ws.
  Proof. intros R p q H l p' pp'. destruct (H _ _ pp'). eauto using etrans_wtrans_. Qed.

  Lemma s_w: ss eq <= ws.
  Proof. rewrite s_e. apply e_w. Qed.

  Corollary sbisim_wbisim: sbisim eq <= wbisim.
  Proof.
    apply gfp_leq.
    (* apply Coinduction.lattice.cap_leq. apply s_w.
    intros R p q. apply (@s_w (R°) q p).
     *)
  Admitted.

  #[global] Instance sbisim_wbisim_subrelation : subrelation (sbisim eq) wbisim.
  Proof.
    apply sbisim_wbisim.
  Qed.

(*|
Since [wt R] contains [wbisim] that contains [sbisim] which is known to be reflexive,
it is reflexive as well
|*)
    #[global] Instance Reflexive_wt R: Reflexive (wt R).
    Proof. intro. apply (gfp_t wb). now apply sbisim_wbisim. Qed.

(*|
[converse] is compatible
|*)
    Lemma converse_wt: converse <= wt.
    Proof. apply invol_t. Qed.

(*|
Hence [wt R] is always symmetric
|*)
    #[global] Instance Symmetric_wt R: Symmetric (wt R).
    Proof. intros ??. apply (ft_t converse_wt). Qed.

(*|
[wbism] is closed under [equ]
|*)
    #[global] Instance equ_wbisim_compat_goal : Proper (equ eq ==> equ eq ==> flip impl) wbisim.
    Proof.
      intros t t' eqt u u' equ; cbn.
      revert t t' u u' eqt equ.
      unfold wbisim; coinduction ? CIH; fold wbisim in *.
      intros * eqt equ eqtu.
      step in eqtu.
      destruct eqtu as [ftu btu].
      split.
      + intros ? ? ?.
        rewrite eqt in H.
        apply ftu in H as [?u' T eq].
        eexists. rewrite equ. apply T.
        eapply CIH; try reflexivity; auto.
      + intros ? ? ?.
        rewrite equ in H.
        apply btu in H as [?t' T eq].
        eexists. rewrite eqt. apply T.
        eapply CIH; try reflexivity; auto.
    Qed.

    #[global] Instance equ_wbisim_compat_ctx : Proper (equ eq ==> equ eq ==> impl) wbisim.
    Proof.
      intros t t' eqt u u' equ; cbn.
      revert t t' u u' eqt equ.
      unfold wbisim; coinduction ? CIH; fold wbisim in *.
      intros * eqt equ eqtu.
      step in eqtu.
      destruct eqtu as [ftu btu].
      split.
      + intros ? ? ?.
        rewrite <- eqt in H.
        apply ftu in H as [?u' T eq].
        eexists. rewrite <- equ. apply T.
        eapply CIH; try reflexivity; auto.
      + intros ? ? ?.
        rewrite <- equ in H.
        apply btu in H as [?t' T eq].
        eexists. rewrite <- eqt. apply T.
        eapply CIH; try reflexivity; auto.
    Qed.

(*|
Hence [equ eq] is a included in [wbisim]
|*)
    #[global] Instance equ_wbisim_subrelation : subrelation (equ eq) wbisim.
    Proof.
      red; intros.
      rewrite H; reflexivity.
    Qed.

(*|
Transitivity
~~~~~~~~~~~~
As for weak bisimulation on process algebra, [square] is not a valid
enhancing function (an explicit counter example is provided below,
see [not_square_wt]).
Weak bisimilariy is however transitive nonetheless. We can actually
reproduce directly Pous' proof for CCS, the relation between [trans] and [wtrans]
being exactly the same in both cases, even if the underlying objects
and transitions are completely different.
|*)

(*|
Moving to the [srel] world once again to establish algebaric laws based
on operators from the relation algebra library.
|*)
    #[local] Instance equ_wbisim_compat : Proper (equ eq ==> equ eq ==> iff) wbisim.
    Proof.
      split; intros.
      now rewrite <- H, <- H0.
      now rewrite H, H0.
    Qed.

    Definition wbisimT : srel SS SS :=
      {| hrel_of := wbisim : hrel SS SS |}.

(*|
Algebraic reformulation of the right-to-left part of the game

Note: We can express these laws in the setoid world or not.
Unclear if there's a benefit to either at this point, we do everything
on the setoid side.
|*)
    Lemma wbisim_trans_back l: wbisimT ⋅ trans l ≦ wtrans l ⋅ wbisimT.
    Proof.
      intros p q' [q pq qq']. apply (gfp_pfp wb) in pq as [_ pq]. now apply pq.
    Qed.
    Lemma wbisim_trans_back' l: wbisim ⋅ transR l ≦ (wtrans l : hrel _ _) ⋅ wbisim.
    Proof.
      intros p q' [q pq qq']. (*apply (gfp_pfp wb) in pq as [_ pq]. now apply pq.
    Qed.*) Admitted. (* FIXME *)
    Lemma wbisim_etrans_back l: wbisimT ⋅ etrans l ≦ wtrans l ⋅ wbisimT.
    Proof.
      unfold etrans; destruct l.
      2,3: apply @wbisim_trans_back.
      ra_normalise. rewrite wbisim_trans_back.
      unfold wtrans, etrans. ka.
    Qed.
    Lemma wbisim_taus_back: wbisimT ⋅ (trans tau)^* ≦ (trans tau)^* ⋅ wbisimT.
    Proof.
      rewrite <-str_invol at 2.
      apply str_move_l. rewrite wbisim_trans_back. unfold wtrans, etrans. ka.
    Qed.
    Lemma wbisim_wtrans_back l: wbisimT ⋅ wtrans l ≦ wtrans l ⋅ wbisimT.
    Proof.
      unfold wtrans.
      mrewrite wbisim_taus_back.
      mrewrite wbisim_etrans_back.
      mrewrite wbisim_taus_back.
      unfold wtrans, etrans. ka.
    Qed.

    Lemma cnv_wt R: (wt R: hrel _ _)° ≡ wt R.
    Proof. apply RelationAlgebra.lattice.antisym; intros ???; now apply Symmetric_wt. Qed.
    Lemma cnv_gfp: RelationAlgebra.lattice.weq ((gfp wb: hrel _ _)°) (gfp wb).
    Proof. apply cnv_wt. Qed.
    Lemma cnv_wbisim: wbisimT° ≡ wbisimT.
    Proof. apply cnv_wt. Qed.
    Lemma cnv_wbisim': wbisim° ≡ wbisim.
    Proof. apply cnv_wt. Qed.


(*|
By symmetry, similar results for left-to-right game
|*)
    Lemma wbisim_trans_front l: (trans l)° ⋅ wbisimT ≦ wbisimT ⋅ (wtrans l)°.
    Proof. cnv_switch. rewrite 2cnvdot, cnv_invol, cnv_wbisim. apply wbisim_trans_back. Qed.
    Lemma wbisim_etrans_front l: (etrans l)° ⋅ wbisimT ≦ wbisimT ⋅ (wtrans l)°.
    Proof. cnv_switch. rewrite 2cnvdot, cnv_invol, cnv_wbisim. apply wbisim_etrans_back. Qed.
    Lemma wbisim_wtrans_front l: (wtrans l)° ⋅ wbisimT ≦ wbisimT ⋅ (wtrans l)°.
    Proof. cnv_switch. rewrite 2cnvdot, cnv_invol, cnv_wbisim. apply wbisim_wtrans_back. Qed.

(*|
Explicit, non-algebraic version
|*)
    Lemma wbisim_wtrans_front_ p q l p': wtrans l p p' -> p ≈ q -> exists2 q', p' ≈ q' & @wtrans E C X _ l q q'.
    Proof. intros pp' pq. apply wbisim_wtrans_front. now exists p. Qed.

(*|
Finally, the proof of transitivity
|*)
    #[global] Instance Transitive_wbisim: Transitive wbisim.
    Proof.
      assert (square wbisim <= wbisim) as H.
      apply leq_gfp. apply symmetric_pfp.
      rewrite converse_square.
      apply square. simpl. apply cnv_gfp.
      intros x z [y xy yz] l x' xx'.
      (*apply (gfp_pfp wb) in xy as [xy _].
      destruct (xy _ _ xx') as [y' yy' x'y'].
      destruct (wbisim_wtrans_front_ _ _ _ _ yy' yz) as [z' y'z' zz'].
      exists z'. assumption. now exists y'.
      intros x y z xy yz. apply H. now exists y.
    Qed.*) Admitted.

    #[global] Instance Equivalence_wbisim: Equivalence wbisim.
    Proof.
      split; typeclasses eauto.
    Qed.

(*|
We can now easily derive that [wbisim] is closed under [sbisim]
|*)
    #[global] Instance sbisim_wbisim_closed_goal :
      Proper (sbisim eq ==> sbisim eq ==> flip impl) wbisim.
    Proof.
      repeat intro.
      now rewrite H, H0.
    Qed.

    #[global] Instance sbisim_wbisim_closed_ctx :
      Proper (sbisim eq ==> sbisim eq ==> impl) wbisim.
    Proof.
      repeat intro.
      now rewrite <- H, <- H0.
    Qed.

#[global] Opaque wtrans.

(*|
Weak bisimulation up-to [equ] is valid
|*)
    Lemma equ_clos_wt : @equ_clos E E C C X X <= wt.
    Proof.
      apply Coinduction, by_Symmetry; [apply equ_clos_sym |].
      intros R t u EQ l t1 TR; inv EQ.
      destruct HR as [F _]; cbn in *.
      rewrite Equt in TR.
      apply F in TR.
      destruct TR as [? ? ?].
      eexists.
      rewrite <- Equu; eauto.
      apply (f_Tf wb).
      econstructor; intuition.
      auto.
    Qed.

(*|
We can therefore rewrite [equ] in the middle of bisimulation proofs
|*)
    #[global] Instance equ_clos_wt_proper_goal RR :
      Proper (equ eq ==> equ eq ==> flip impl) (wt RR).
    Proof.
      cbn; unfold Proper, respectful; intros.
      apply (ft_t equ_clos_wt).
      econstructor; [eauto | | symmetry; eauto]; auto.
    Qed.

    #[global] Instance equ_clos_wt_proper_ctx RR :
      Proper (equ eq ==> equ eq ==> impl) (wt RR).
    Proof.
      cbn; unfold Proper, respectful; intros.
      apply (ft_t equ_clos_wt).
      econstructor; [symmetry; eauto | | eauto]; auto.
    Qed.

(*|
Contrary to what happens with [sbisim], weak bisimulation ignores both kinds of taus
|*)
    Lemma guard_wb `{B1 -< C} : forall (t : ctree E C X),
        Guard t ≈ t.
    Proof.
      intros. now rewrite sb_guard.
    Qed.

    Lemma step_wb `{HasTau : B1 -< C} : forall (t : ctree E C X),
        Step t ≈ t.
    Proof.
      intros t; step; split.
      - intros l t' H.
        apply trans_step_inv in H as [EQ ->].
        exists t'.
        rewrite EQ. apply wnil.
        reflexivity.
      - intros l t' H. exists t'.
        apply wtrans_step.
        apply trans_wtrans; auto.
        cbn; reflexivity.
    Qed.

(*|
Disproving the transitivity of [wt R]
-------------------------------------
|*)

    Lemma not_Transitive_wt `{HasTau : B1 -< C} Z: X -> Z -> E Z -> ~ forall R, Transitive (wt R).
    Proof.
      intros x z e H.
      cut (Vis e (fun _ => Ret x) ≈ (Ret x : ctree E C X)).
      - intros abs. step in abs; destruct abs as [abs _].
        destruct (abs (obs e z) (Ret x)) as [? step EQ].
        constructor; reflexivity.
        apply wtrans_ret_inv in step as [[abs' ?] | [abs' ?]]; inv abs'.
      - rewrite <- step_wb.
        rewrite <- (step_wb (Ret x)).
        unfold wbisim; coinduction ? CIH; fold wbisim in *.
        split.
        + intros l t' tt'.
          apply trans_step_inv in tt' as [EQ ->].
          exists (Ret x); auto.
          apply trans_wtrans; constructor; [exact tt | reflexivity].
          apply equ_wbisim_subrelation in EQ.
          rewrite EQ.
          rewrite <- (subrelation_gfp_t _ (step_wb _)).
          rewrite <- (subrelation_gfp_t _ (step_wb (Ret x))).
          assumption.  (* Here clearly some instances are missing, the rewrite do not work in the other order, and should not require such an explicit low level call *)
        + intros ? ? ?.
          apply trans_step_inv in H0 as [EQ ->].
          eexists.
          apply trans_wtrans; constructor; [exact tt | reflexivity].
          cbn.
          apply equ_wbisim_subrelation in EQ.
          rewrite <- (subrelation_gfp_t _ (step_wb _)).
          symmetry.
          rewrite EQ.
          rewrite <- (subrelation_gfp_t _ (step_wb _)).
          symmetry.
          assumption.
    Qed.

    Lemma not_square_wt `{HasTau : B1 -< C} Z: X -> Z -> E Z -> ~ square <= wt.
    Proof.
      intros x z e H. elim (not_Transitive_wt _ x z e). intro R.
      intros ? y ???. apply (ft_t H). now exists y.
    Qed.

End wbisim_theory.

Section bind.

  Obligation Tactic := idtac.
  Context {E C : Type -> Type} {X Y: Type} `{HasStuck : B0 -< C}.

(*|
Specialization of [bind_ctx] to a function acting with [sbisim] on the bound value,
and with the argument (pointwise) on the continuation.
|*)
  Program Definition bind_ctx_wbisim :  mon (rel (ctree E C Y) (ctree E C Y)) :=
    {|body := fun R => @bind_ctx E E C C X X Y Y wbisim (pointwise eq R) |}.
  Next Obligation.
    intros ???? H. apply leq_bind_ctx. intros ?? H' ?? H''.
    apply in_bind_ctx. apply H'. intros t t' HS. apply H0, H'', HS.
  Qed.

(*|
Sufficient condition to exploit symmetry
|*)
    Lemma bind_ctx_wbisim_sym: compat converse bind_ctx_wbisim.
    Proof.
      intro R. simpl. apply leq_bind_ctx. intros. apply in_bind_ctx.
      symmetry; auto.
      intros ? ? ->.
      apply H0; auto.
    Qed.

(*|
The resulting enhancing function gives a valid up-to technique
|*)
    Lemma bind_ctx_wbisim_t : bind_ctx_wbisim <= wt.
    Proof.
      apply Coinduction, by_Symmetry.
      apply bind_ctx_wbisim_sym.
      intros R. apply (leq_bind_ctx _).
      intros t1 t2 tt k1 k2 kk.
      step in tt; destruct tt as (F & B); cbn in *.
      cbn in *; intros l u STEP.
      apply trans_bind_inv in STEP as [(H & t' & STEP & EQ) | (v & STEPres & STEP)]; cbn in *.
      - apply F in STEP as [u' STEP EQ'].
        eexists.
        apply wtrans_bind_l; eauto.
        apply (fT_T equ_clos_wt).
        econstructor; [exact EQ | | reflexivity].
        apply (fTf_Tf wb).
        apply in_bind_ctx; auto.
        intros ? ? ->.
        apply (b_T wb).
        apply kk; auto.
      - clear B.
        (* Things are tricky, the bind inversion rule is messy *)
        specialize (kk v v eq_refl).
        destruct kk as [F' _].
        apply F  in STEPres as [x STEPres EQ].
        apply F' in STEP    as [u' STEP HR].
        pose proof (wtrans_val_inv' STEPres) as (? & wtr & ? & EQ').
        rewrite EQ' in STEPres.
        pose proof wtrans_bind_r _ STEPres STEP as [EQ'' | ?].
        + rewrite EQ'' in STEP.
          assert (l = tau) by admit.
          subst.
          exists (k2 v).
          admit.
          admit.
        + admit.

    Admitted.

End bind.

(*|
Expliciting the reasoning rule provided by the up-to principles.
|*)
Lemma wbisim_clo_bind (E C: Type -> Type) (X Y : Type) `(HasStuck : B0 -< C) :
	forall (t1 t2 : ctree E C X) (k1 k2 : X -> ctree E C Y) RR,
		t1 ≈ t2 ->
    (forall x, (wt RR) (k1 x) (k2 x)) ->
    wt RR (t1 >>= k1) (t2 >>= k2)
.
Proof.
  intros.
  apply (ft_t (@bind_ctx_wbisim_t E C X Y _)).
  apply in_bind_ctx; auto.
  intros ? ? <-; auto.
Qed.

(*|
And in particular, we get the proper instance justifying rewriting [~]
and [≈] to the left of a [bind].
|*)
#[global] Instance bind_wbisim_cong :
 forall (E C : Type -> Type) (X Y : Type) `{B0 -< C} (R : rel Y Y) RR,
   Proper (wbisim ==> pointwise_relation X (wt RR) ==> wt RR) (@bind E C X Y).
Proof.
  repeat red; intros; eapply wbisim_clo_bind; eauto.
Qed.

Lemma wbisim_ret_inv {E C R} `{B0 -< C} : forall (x y : R),
    Ret x ≈ (Ret y : ctree E C R) ->
    x = y.
Proof.
  intros * EQ.
   ewplayL.
  apply wtrans_case' in TR as [(?v & TR & WTR)|(?v & TR & WTR)].
  inv_trans; auto.
  inv_trans; auto.
Qed.

(*|
Note: with brD2, these relations hold up-to strong bisimulation.
With brS2 however they don't even hold up-to weak bisimulation.
|*)
(*
Lemma spinS_nary_0 : forall {E R}, @spinS_nary E R 0 ≈ spinS_nary 0.
Proof.
  intros E R.
  reflexivity.
Qed.*)

Ltac wcase :=
  match goal with
    [ h   : hrel_of (wtrans ?l) _ _,
      bis : wbisim _ _
      |- _] =>
      let EQ := fresh "EQ" in
      match l with
      | tau => apply wtrans_case' in h as [EQ|(? & ?TR & ?WTR)];
              [rewrite <- EQ in bis; clear EQ |]
      | _   => apply wtrans_case' in h as [(? & ?TR & ?WTR)|(? & ?TR & ?WTR)]
      end
  end.

#[local] Arguments trans_brS21 [_ _].
#[local] Arguments trans_brS22 [_ _].
#[local] Arguments trans_ret [_ _] _.

(*|
With brS2 however they don't even hold up-to weak bisimulation.
The proof is not interesting, but it would be good to have a
light way to automate it, so it's a decent case study.
|*)
(*
Lemma brS2_not_assoc :
	~ (brS2 (brS2 (Ret 0 : ctree Sum.void1 nat) (Ret 1)) (Ret 2) ≈ brS2 (Ret 0) (brS2 (Ret 1) (Ret 2)))%nat.
Proof.
  intros abs.

  (* init: 012 || 012 *)
  wplayL trans_brS21.

  (* PL  : 01  || 012 *)
  wcase.
  - (* AR:  01  || 012 *)
    wplayR trans_brS22.
    (* PR:  01  ||  12 *)
    wcase.
    + (* AL:  01  ||  12 *)
      wplayR trans_brS22.
      (* PR:  01  ||   2 *)
      wcase.
      * (* AL: 01  ||   2 *)
        wplayR trans_ret.
        (* PR: 01  |2?|   ∅ *)
        wcase.
        (* AL: steps with 2, abs *)
        inv_trans.
        inv_trans.
        (* PR: 0   ||   ∅ *)
        wcase; inv_trans.
        (* PR: 1   ||   ∅ *)
        wcase; inv_trans.
      * inv_trans.
        (* AL: 0  ||   2 *)
        wcase.
        apply wbisim_ret_inv in EQ; inv EQ.
        inv_trans.
        (* AL: 1  ||   2 *)
        wcase.
        apply wbisim_ret_inv in EQ; inv EQ.
        inv_trans.
    + inv_trans.
      * (* AL:  0  ||  12 *)
        wcase.
        wplayL trans_ret.
        wcase; inv_trans.
        wcase; inv_trans.
        wcase; inv_trans.
        inv_trans.
      * (* AL:  1  ||  12 *)
        wcase.
        wplayR trans_brS22.
        wcase.
        apply wbisim_ret_inv in EQ; inv EQ.
        inv_trans.
        inv_trans.
  - inv_trans.
    + wcase.
      * wplayL trans_brS22.
        wcase.
        apply wbisim_ret_inv in EQ; inv EQ.
        inv_trans.
      * inv_trans.
    + wcase.
      wplayL trans_brS21.
      wcase.
      wplayL trans_ret.
      wcase.
      inv_trans.
      inv_trans.
      wcase; inv_trans.
      wcase; inv_trans.
      inv_trans.
      wcase.
      apply wbisim_ret_inv in EQ; inv EQ.
      inv_trans.
      wcase.
      apply wbisim_ret_inv in EQ; inv EQ.
      inv_trans.
      inv_trans.
      wcase.
      wplayL trans_brS21.
      wcase.
      apply wbisim_ret_inv in EQ; inv EQ.
      inv_trans.
      inv_trans.
      wcase.
      wplayL trans_brS21.
      wcase.
      apply wbisim_ret_inv in EQ; inv EQ.
      inv_trans.
      inv_trans.
Qed.*)