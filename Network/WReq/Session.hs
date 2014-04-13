module Network.WReq.Session
    (
      Session
    , new
    -- * HTTP verbs
    , get
    , post
    , head
    , options
    , put
    , delete
    -- ** Configurable verbs
    , getWith
    , postWith
    , headWith
    , optionsWith
    , putWith
    , deleteWith
    ) where

import Control.Concurrent.MVar (MVar, modifyMVar, newMVar)
import Control.Lens ((&), (.~), (^.))
import Network.WReq (Options, Payload, Response, defaults)
import Prelude hiding (head)
import qualified Data.ByteString.Lazy as L
import qualified Network.HTTP.Client as HTTP
import qualified Network.WReq as WReq

newtype Session = Session {
      seshCookies :: MVar HTTP.CookieJar
    } deriving (Eq)

instance Show Session where
    show _ = "Session"

new :: IO Session
new = do
  ref <- newMVar $ HTTP.createCookieJar []
  return Session { seshCookies = ref }

get :: Session -> String -> IO (Response L.ByteString)
get = getWith defaults

post :: Session -> String -> Payload -> IO (Response L.ByteString)
post = postWith defaults

head :: Session -> String -> IO (Response ())
head = headWith defaults

options :: Session -> String -> IO (Response ())
options = optionsWith defaults

put :: Session -> String -> Payload -> IO (Response L.ByteString)
put = putWith defaults

delete :: Session -> String -> IO (Response ())
delete = deleteWith defaults

getWith :: Options -> Session -> String -> IO (Response L.ByteString)
getWith opts sesh url =
  override opts sesh $ \opts' -> WReq.getWith opts' url

postWith :: Options -> Session -> String -> Payload
         -> IO (Response L.ByteString)
postWith opts sesh url payload =
  override opts sesh $ \opts' -> WReq.postWith opts' url payload

headWith :: Options -> Session -> String -> IO (Response ())
headWith opts sesh url =
  override opts sesh $ \opts' -> WReq.headWith opts' url

optionsWith :: Options -> Session -> String -> IO (Response ())
optionsWith opts sesh url =
  override opts sesh $ \opts' -> WReq.optionsWith opts' url

putWith :: Options -> Session -> String -> Payload -> IO (Response L.ByteString)
putWith opts sesh url payload =
  override opts sesh $ \opts' -> WReq.putWith opts' url payload

deleteWith :: Options -> Session -> String -> IO (Response ())
deleteWith opts sesh url =
  override opts sesh $ \opts' -> WReq.deleteWith opts' url

override :: Options -> Session -> (Options -> IO (Response body))
         -> IO (Response body)
override opts sesh act =
  modifyMVar (seshCookies sesh) $ \cj -> do
    resp <- act (opts & WReq.cookies .~ cj)
    return (resp ^. WReq.responseCookieJar, resp)
