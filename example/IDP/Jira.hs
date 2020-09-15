{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}

module IDP.Jira where
import           Data.Aeson
import           Data.Bifunctor
import           Data.Hashable
import           Data.Text.Lazy       (Text)
import           GHC.Generics
import           Keys
import           Network.OAuth.OAuth2
import           Types
import           URI.ByteString
import           URI.ByteString.QQ
import           Utils

data Jira = Jira deriving (Show, Generic)

instance Hashable Jira

instance IDP Jira

instance HasLabel Jira

instance HasTokenReq Jira where
  tokenReq _ mgr = fetchAccessToken mgr jiraKey

instance HasTokenRefreshReq Jira where
  tokenRefreshReq _ mgr = refreshAccessToken mgr jiraKey

instance HasUserReq Jira where
  userReq _ mgr at = do
    re <- authGetJSON mgr at userInfoUri
    return (second toLoginUser re)

instance HasAuthUri Jira where
  authUri _ = createCodeUri jiraKey [ ("state", "Jira.test-state-123")
                                    , ("scope", "offline_access read:jira-user read:jira-work read:me")
                                    , ("audience", "api.atlassian.com")
                                    , ("prompt", "consent")
                                    ]

data JiraUser = JiraUser { email :: Text
                         , name :: Text
                         , accountId :: Text
                         , nickname :: Text
                         } deriving (Show, Generic)

instance FromJSON JiraUser where
    parseJSON = genericParseJSON defaultOptions { fieldLabelModifier = camelTo2 '_' }

userInfoUri :: URI
userInfoUri = [uri|https://api.atlassian.com/me|]

-- userInfoUri = [uri|https://api.atlassian.com/ex/jira/{cloud_id}/rest/api/3/myself|]
{-
-- https://developer.atlassian.com/cloud/jira/platform/oauth-2-authorization-code-grants-3lo-for-apps/
-- use following to retrieve cloud id using access token
curl --request GET \
  --url https://api.atlassian.com/oauth/token/accessible-resources \
  --header 'Authorization: Bearer ACCESS_TOKEN' \
  --header 'Accept: application/json'
-}

toLoginUser :: JiraUser -> LoginUser
toLoginUser auser = LoginUser { loginUserName = name auser
                                <> ", "
                                <> email auser
                                <> ", "
                                <> accountId auser
                              }
