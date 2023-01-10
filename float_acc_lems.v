Require Import vcfloat.VCFloat.
Require Import common op_defs.

Section NAN.

Lemma neg_zero_is_finite t:
Binary.is_finite (fprec t) (femax t) neg_zero = true.
Proof. simpl; auto. Qed.

Definition fma_no_overflow (t: type) (x y z: R) : Prop :=
  (Rabs (rounded t  (x * y + z)) < Raux.bpow Zaux.radix2 (femax t))%R.

Definition Bmult_no_overflow (t: type) (x y: R) : Prop :=
  (Rabs (rounded t  (x * y)) < Raux.bpow Zaux.radix2 (femax t))%R.


Lemma generic_round_property:
  forall (t: type) (x: R),
exists delta epsilon : R,
   delta * epsilon = 0 /\
  (Rabs delta <= default_rel t)%R /\
  (Rabs epsilon <= default_abs t)%R /\
   Generic_fmt.round Zaux.radix2
              (SpecFloat.fexp (fprec t) (femax t))
              (BinarySingleNaN.round_mode BinarySingleNaN.mode_NE)
               x = (x * (1+delta)+epsilon)%R.
Proof.
intros.
destruct (Relative.error_N_FLT Zaux.radix2 (SpecFloat.emin (fprec t) (femax t)) (fprec t) 
             (fprec_gt_0 t) (fun x0 : Z => negb (Z.even x0)) x)
  as [delta [epsilon [? [? [? ?]]]]].
exists delta, epsilon.
split; [ | split]; auto.
Qed.

Lemma fma_accurate {NAN: Nans} : 
   forall (t: type) 
             x (FINx: Binary.is_finite (fprec t) (femax t) x = true) 
             y (FINy: Binary.is_finite (fprec t) (femax t) y = true) 
             z (FINz: Binary.is_finite (fprec t) (femax t) z = true)
          (FIN: fma_no_overflow t (FT2R x) (FT2R y) (FT2R z)), 
  exists delta, exists epsilon,
   delta * epsilon = 0 /\
   Rabs delta <= default_rel t /\
   Rabs epsilon <= default_abs t /\ 
   (FT2R (BFMA x y z) = (FT2R x * FT2R y + FT2R z) * (1+delta) + epsilon)%R.
Proof.
intros.
pose proof (Binary.Bfma_correct  (fprec t) (femax t)  (fprec_gt_0 t) (fprec_lt_femax t) (fma_nan t)
                      BinarySingleNaN.mode_NE x y z FINx FINy FINz).
change (Binary.B2R (fprec t) (femax t) ?x) with (@FT2R t x) in *.
cbv zeta in H.
pose proof (
   Raux.Rlt_bool_spec
        (Rabs
           (Generic_fmt.round Zaux.radix2
              (SpecFloat.fexp (fprec t) (femax t))
              (BinarySingleNaN.round_mode
                 BinarySingleNaN.mode_NE) (FT2R x * FT2R y + FT2R z)))
        (Raux.bpow Zaux.radix2 (femax t))).
destruct H0.
-
destruct H as [? _].
fold (@BFMA NAN t) in H.
rewrite H.
apply generic_round_property.
-
red in FIN. unfold rounded in FIN.
Lra.lra.
Qed.

Lemma BMULT_accurate {NAN: Nans}: 
   forall (t: type) x y (FIN: Bmult_no_overflow t (FT2R x) (FT2R y)), 
  exists delta, exists epsilon,
   delta * epsilon = 0 /\
   Rabs delta <= default_rel t /\
   Rabs epsilon <= default_abs t /\ 
   (FT2R (BMULT t x y) = (FT2R x * FT2R y) * (1+delta) + epsilon)%R.
Proof.
intros.
pose proof (Binary.Bmult_correct (fprec t) (femax t) (fprec_gt_0 t) (fprec_lt_femax t) 
                (mult_nan t) BinarySingleNaN.mode_NE x y).
change (Binary.B2R (fprec t) (femax t) ?x) with (@FT2R t x) in *.
cbv zeta in H.
pose proof (
   Raux.Rlt_bool_spec
        (Rabs
           (Generic_fmt.round Zaux.radix2
              (SpecFloat.fexp (fprec t) (femax t))
              (BinarySingleNaN.round_mode
                 BinarySingleNaN.mode_NE) (FT2R x * FT2R y)))
        (Raux.bpow Zaux.radix2 (femax t))).
destruct H0.
destruct H as [? _].
unfold BMULT, BINOP.
rewrite H.
apply generic_round_property.
red in FIN. unfold rounded in FIN.
Lra.lra.
Qed.

Lemma is_finite_fma_no_overflow {NAN: Nans} (t : type) :
  forall fma x y z
  (HFINb : Binary.is_finite (fprec t) (femax t) fma = true)
  (HEQ   : fma = BFMA x y z),
  let ov := bpow Zaux.radix2 (femax t) in
  Rabs (rounded t (FT2R x * FT2R y + FT2R z)) < ov.
Proof.
intros.
pose proof Rle_or_lt ov (Rabs (rounded t (FT2R x * FT2R y + FT2R z)))  as Hor;
  destruct Hor; auto.
apply Rlt_bool_false in H.
rewrite HEQ in HFINb.
assert (HFIN: Binary.is_finite (fprec t) (femax t) x = true /\
  Binary.is_finite (fprec t) (femax t) y = true /\ 
  Binary.is_finite (fprec t) (femax t) z = true).
{ unfold BFMA in HFINb. 
    destruct x; destruct y; destruct z; simpl in *; try discriminate; auto.
    all: destruct s; destruct s0; destruct s1; simpl in *; try discriminate; auto. }
destruct HFIN as (A & B & C).
unfold rounded, FT2R, ov in H.
pose proof (Binary.Bfma_correct  (fprec t) (femax t)  
    (fprec_gt_0 t) (fprec_lt_femax t) (fma_nan t) BinarySingleNaN.mode_NE x y z A B C) as
  H0.
simpl in H0; simpl in H;
rewrite H in H0.
assert (H1: Binary.B2FF _ _ (BFMA x y z) = Binary.B2FF _ _ fma) by
  (f_equal; auto).
unfold BFMA in H1.
rewrite H0 in H1; clear H0.
rewrite <- HEQ in HFINb.
destruct fma;
simpl; intros; try discriminate.
Qed.

Lemma is_finite_BMULT_no_overflow {NAN: Nans} (t : type) :
  forall a x y 
  (HFINb : Binary.is_finite (fprec t) (femax t) a = true)
  (HEQ   : a = BMULT t x y ),
  let ov := bpow Zaux.radix2 (femax t) in
  Rabs (rounded t (FT2R x * FT2R y)) < ov.
Proof.
intros.
pose proof Rle_or_lt ov (Rabs (rounded t (FT2R x * FT2R y)))  as Hor;
  destruct Hor; auto.
apply Rlt_bool_false in H.
rewrite HEQ in HFINb.
unfold rounded, FT2R, ov in H.
pose proof (Binary.Bmult_correct  (fprec t) (femax t)  
    (fprec_gt_0 t) (fprec_lt_femax t) (mult_nan t) BinarySingleNaN.mode_NE x y) as
  H0.
simpl in H0; simpl in H;
rewrite H in H0.
assert (H1: Binary.B2FF _ _ (BMULT t x y ) = Binary.B2FF _ _ a) by
  (f_equal; auto).
unfold BMULT, BINOP in H1.
rewrite H0 in H1; clear H0.
rewrite <- HEQ in HFINb.
destruct a;
simpl; intros; try discriminate.
Qed.

Definition Bplus_no_overflow (t: type) (x y: R) : Prop :=
  (Rabs ( Generic_fmt.round Zaux.radix2
              (SpecFloat.fexp (fprec t) (femax t))
              (BinarySingleNaN.round_mode
                 BinarySingleNaN.mode_NE)  (x + y )) < Raux.bpow Zaux.radix2 (femax t))%R.

Lemma BPLUS_neg_zero {NAN: Nans} (t : type) (a : ftype t) :
  Binary.is_finite _ _ a = true ->
  BPLUS t a neg_zero = a.
Proof.
destruct a; unfold neg_zero; simpl; try discriminate; auto.
destruct s; auto.
Qed.

Lemma BPLUS_accurate {NAN: Nans} (t : type) :
 forall      x (FINx: Binary.is_finite (fprec t) (femax t) x = true) 
             y (FINy: Binary.is_finite (fprec t) (femax t) y = true) 
          (FIN: Bplus_no_overflow t (FT2R x) (FT2R y)), 
  exists delta, 
   Rabs delta <= default_rel t /\
   (FT2R (BPLUS t x y ) = (FT2R x + FT2R y) * (1+delta))%R.
Proof.
intros. 
pose proof (Binary.Bplus_correct  (fprec t) (femax t)  (fprec_gt_0 t) (fprec_lt_femax t) (plus_nan t)
                      BinarySingleNaN.mode_NE x y FINx FINy).
change (Binary.B2R (fprec t) (femax t) ?x) with (@FT2R t x) in *.
cbv zeta in H.
pose proof (
   Raux.Rlt_bool_spec
        (Rabs
           (Generic_fmt.round Zaux.radix2
              (SpecFloat.fexp (fprec t) (femax t))
              (BinarySingleNaN.round_mode
                 BinarySingleNaN.mode_NE) (FT2R x + FT2R y)))
        (Raux.bpow Zaux.radix2 (femax t))).
destruct H0.
-
destruct H as [? _].
unfold BPLUS, BINOP.
rewrite H. 
assert (A: Generic_fmt.generic_format Zaux.radix2
       (FLT.FLT_exp (SpecFloat.emin (fprec t) (femax t)) (fprec t))
       (FT2R x) ) by (apply Binary.generic_format_B2R).
assert (B: Generic_fmt.generic_format Zaux.radix2
       (FLT.FLT_exp (SpecFloat.emin (fprec t) (femax t)) (fprec t))
       (FT2R y) ) by (apply Binary.generic_format_B2R).
pose proof Plus_error.FLT_plus_error_N_ex   Zaux.radix2 (SpecFloat.emin (fprec t) (femax t))
 (fprec t) (fun x0 : Z => negb (Z.even x0)) (FT2R x) (FT2R y) A B.
unfold Relative.u_ro in H1. fold (default_rel t) in H1.
destruct H1 as (d & Hd & Hd').
 
assert (  Generic_fmt.round Zaux.radix2 (SpecFloat.fexp (fprec t) (femax t))
    (BinarySingleNaN.round_mode BinarySingleNaN.mode_NE)
    (FT2R x + FT2R y)  =  Generic_fmt.round Zaux.radix2
        (FLT.FLT_exp (SpecFloat.emin (fprec t) (femax t)) (fprec t))
        (Generic_fmt.Znearest (fun x0 : Z => negb (Z.even x0)))
        (FT2R x + FT2R y)) by auto.
rewrite <- H1 in Hd'. clear H1. rewrite Hd'; clear Hd'.
exists d; split; auto.
eapply Rle_trans; [apply Hd |].
apply Rdiv_le_left.
apply Fourier_util.Rlt_zero_pos_plus1. 
apply default_rel_gt_0.
eapply Rle_trans with (default_rel t * 1); try nra.
-
red in FIN.
Lra.lra.
Qed.



Lemma is_finite_sum_no_overflow {NAN: Nans} (t : type) :
  forall a x y
  (HFINb : Binary.is_finite (fprec t) (femax t) a = true)
  (HEQ   : a = BPLUS t x y),
  let ov := bpow Zaux.radix2 (femax t) in
  Rabs (rounded t (FT2R x + FT2R y)) < ov.
Proof.
intros.
pose proof Rle_or_lt ov (Rabs (rounded t (FT2R x + FT2R y)))  as Hor;
  destruct Hor; auto.
apply Rlt_bool_false in H.
rewrite HEQ in HFINb.
assert (HFIN: Binary.is_finite (fprec t) (femax t) x = true /\
  Binary.is_finite (fprec t) (femax t) y = true).
{ unfold BPLUS, BINOP in HFINb. 
    destruct x; destruct y; simpl in *; try discriminate; auto.
    destruct s; destruct s0; simpl in *; try discriminate; auto.
}
destruct HFIN as (A & B).
unfold rounded, FT2R, ov in H.
pose proof (Binary.Bplus_correct  (fprec t) (femax t)  
    (fprec_gt_0 t) (fprec_lt_femax t) (plus_nan t) BinarySingleNaN.mode_NE x y A B) as
  H0;
rewrite H in H0;
destruct H0 as ( C & _).
assert (H1: Binary.B2FF _ _ (BPLUS t x y) = Binary.B2FF _ _ a) by
  (f_equal; auto).
unfold BPLUS, BINOP in H1.
rewrite C in H1; clear C A B.
rewrite <- HEQ in HFINb.
destruct a;
simpl; intros; try discriminate.
Qed.






End NAN.