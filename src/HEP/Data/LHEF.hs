{-# LANGUAGE RecordWildCards #-}

module HEP.Data.LHEF
    ( EventInfo(..)
    , Particle(..)
    , ParIdx
    , ParticleMap
    , Event

    , fourMomentum
    , px
    , py
    , pz
    , energy
    , mass
    , pt

    , finalStates
    , mothers
    , initialStates
    , daughters
    ) where

import           HEP.Vector.LorentzVector

import qualified Data.IntMap as IntMap
import           Data.List (nub)

data EventInfo = EventInfo
    { -- | Number of particle entries in the event.
      nup    :: Int
      -- | ID of the process for the event.
    , idprup :: Int
      -- | Event weight.
    , xwgtup :: Double
      -- | Scale of the event in GeV.
    , scalup :: Double
      -- | The QED coupling \alpha_{QED} used for the event.
    , aqedup :: Double
      -- | The QCD coupling \alpha_{QCD} used for the event.
    , aqcdup :: Double
    } deriving Show

data Particle = Particle
    { -- | Particle ID according to Particle Data Group convention.
      idup     :: Int
      -- | Status code.
    , istup    :: Int
      -- | Index of first and last mother.
    , mothup   :: (Int, Int)
      -- | Integer tag for the color flow line passing through the
      -- (anti-)color of the particle.
    , icolup   :: (Int, Int)
      -- | Lab frame momentum (P_x, P_y, P_z, E, M) of particle in GeV.
    , pup      :: (Double, Double, Double, Double, Double)
      -- | Invariant lifetime (distance from production to decay) in mm.
    , vtimup   :: Double
      -- | Consine of the angle between the spin-vector of particle and
      -- the three-momentum of the decaying particle, specified in the
      -- lab frame.
    , spinup   :: Double
    } deriving Show

instance Eq Particle where
    p == p' = (idup p == idup p') && (pup p == pup p')

instance Ord Particle where
    p >= p' = pt p >= pt p'

type ParIdx = Int

type ParticleMap = IntMap.IntMap Particle

type Event = (EventInfo, ParticleMap)

fourMomentum :: Particle -> LorentzVector Double
fourMomentum Particle { pup = (x, y, z, e, _) } =
    LorentzVector e x y z

px :: Particle -> Double
px Particle { pup = (x, _, _, _, _) } = x

py :: Particle -> Double
py Particle { pup = (_, y, _, _, _) } = y

pz :: Particle -> Double
pz Particle { pup = (_, _, z, _, _) } = z

energy :: Particle -> Double
energy Particle { pup = (_, _, _, e, _) } = e

mass :: Particle -> Double
mass Particle { pup = (_, _, _, _, m) } = m

pt :: Particle -> Double
pt Particle { pup = (x, y, _, _, _) } = sqrt $ x*x + y*y

finalStates :: ParticleMap -> [Particle]
finalStates = IntMap.elems . IntMap.filter (\Particle { .. } -> istup == 1)

mother :: ParticleMap -> Particle -> Maybe Particle
mother pm Particle { mothup = (m, _) } | m `elem` [1, 2] = Nothing
                                       | otherwise       = IntMap.lookup m pm

mothers :: ParticleMap -> Maybe Particle -> [Particle]
mothers pm (Just p) = p : mothers pm (mother pm p)
mothers _  Nothing  = []

initialStates :: ParticleMap -> [Particle]
initialStates pm = nub $ map (ancenstor pm) $ finalStates pm
    where ancenstor pm' p' = last $ mothers pm' (Just p')

daughters :: (ParIdx, Particle) -> ParticleMap -> [Particle]
daughters (i, _) = IntMap.elems .
                   IntMap.filter (\Particle { .. } -> fst mothup == i)
