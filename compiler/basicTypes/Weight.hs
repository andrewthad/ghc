-- TODO: arnaud: copyright notice

{-# LANGUAGE DeriveDataTypeable, DeriveFunctor, DeriveFoldable, DeriveTraversable #-}

-- | This module defines the semi-ring (aka Rig) of weights, and associated
-- functions. Weights annotate arrow types to indicate the linearity of the
-- arrow (in the sense of linear types).
module Weight where
  -- TODO: arnaud list of exports

import Control.Monad
import Data.Data
import Data.String
import Outputable
import Name
import NameEnv

data Rig = Zero | One | Omega
  deriving (Eq,Ord,Data)

instance Num Rig where
  Zero * _ = Zero
  _ * Zero = Zero
  Omega * One = Omega
  One * Omega = Omega
  One * One   = One
  Omega * Omega = Omega

  Zero + x = x
  x + Zero = x
  _ + _ = Omega

instance Outputable Rig where
  ppr Zero = fromString "0"
  ppr One = fromString "1"
  ppr Omega = fromString "ω"


-- | |subweight w1 w2| check whether a value of weight |w1| is allowed where a
-- value of weight |w2| is expected. This is a partial order.
subweight :: Rig -> Rig -> Bool
subweight Zero  Zero  = True
-- It is no mistake: 'Zero' is not a subweight of 'One': a value which must be
-- used zero times cannot be used one time.
subweight Zero  Omega = True
subweight One   One   = True
subweight One   Omega = True
subweight Omega Omega = True
subweight _     _     = False

-- | A shorthand for data with an attached 'Rig' element (the weight).
data Weighted a = Weighted {weightedWeight :: Rig, weightedThing :: a}
  deriving (Functor,Foldable,Traversable,Data)

unrestricted = Weighted Omega
staticOnly = Weighted Zero

instance Outputable a => Outputable (Weighted a) where
   ppr (Weighted cnt t) = ppr cnt <> ppr t

weightedSet :: Weighted a -> b -> Weighted b
weightedSet x b = fmap (\_->b) x


-- | Like in the mathematical presentation, we have a context on which the
-- semi-ring of weights acts (that is, 'UsageEnv' is a 'Rig'-module). Unlike the
-- mathematical presentation they are not type contexts, but only contain
-- weights corresponding to the weight required for a given variable in a
-- type-checked expression. The reason is twofold: it interacts less with the
-- rest of the type-checking infrastructure so it is easier to fit into the
-- existing implementation, and it is always an inferred datum (in the sense of
-- bidirectional type checking, i.e. it is an output of the type-checking
-- procedure) which makes it possible to use addition and scaling like in the
-- mathematical presentation, rather than subtraction and division which are
-- much harder to get right. The module structure is the point-wise extension of
-- the action of 'Rig' on itself, every absent name being considered to map to
-- 'Zero'.
newtype UsageEnv = UsageEnv (NameEnv Rig)

unitUE :: Name -> Rig -> UsageEnv
unitUE x w = UsageEnv $ unitNameEnv x w

mkUE :: [Weighted Name] -> UsageEnv
mkUE ws = UsageEnv $ mkNameEnv (map (\wx -> (weightedThing wx,weightedWeight wx)) ws)

zeroUE :: UsageEnv
zeroUE = UsageEnv emptyNameEnv

addUE :: UsageEnv -> UsageEnv -> UsageEnv
addUE (UsageEnv e1) (UsageEnv e2) = UsageEnv $
  plusNameEnv_C (+) e1 e2

scaleUE :: Rig -> UsageEnv -> UsageEnv
scaleUE w (UsageEnv e) = UsageEnv $
  mapNameEnv (w*) e

-- | |deleteUEAsserting w x env| deletes the binding to |x| in |env| under one
-- condition: if |x| is bound to |w'| in |env|, then |w'| must be a subweight of
-- |w|, if |x| is not bound in |env| then |Zero| must be a subweight of |W|. If
-- the condition is not met, then |Nothing| is returned.
deleteUEAsserting :: Rig -> Name -> UsageEnv -> Maybe UsageEnv
deleteUEAsserting w x (UsageEnv e) | Just w' <- lookupNameEnv e x = do
  guard (subweight w' w)
  return $ UsageEnv (delFromNameEnv e x)
deleteUEAsserting w x (UsageEnv e) = do
  guard (subweight Zero w)
  return $ UsageEnv e
