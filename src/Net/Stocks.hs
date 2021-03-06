{-# LANGUAGE OverloadedStrings #-}

module Net.Stocks
        ( Stock(..)
        , Financials(..)
        , FinancialsList(..)
        , QueryType(..)
        , Company
        , stocksQuery
        , financialsQuery
        , peersQuery
        , priceQuery
        , getData
        , getNonJSONData
        ) where
  
import Control.Monad
import Control.Applicative
import Data.Char
import Data.Aeson
import Data.List.NonEmpty
import Data.ByteString.Lazy.Char8
import Network.HTTP.Conduit

-- | Stock data
data Stock =
    Stock { company          :: String  -- ^ The company's name
          , latestPrice      :: Float   -- ^ Latest stock price
          , latestTime       :: String  -- ^ Timeframe
          , changePercent    :: Float   -- ^ Percentage change
          } deriving (Show)

instance FromJSON Stock where
    parseJSON = withObject "Stock" $ \v -> Stock
        <$> v .: "companyName"
        <*> v .: "latestPrice"
        <*> v .: "latestTime"
        <*> v .: "changePercent"

newtype FinancialsList = FinancialsList { financialsList :: NonEmpty Financials}

instance FromJSON FinancialsList where
    parseJSON = withObject "FinancialsList" $ \v -> FinancialsList 
        <$> v .: "financials"

-- | Financials data
data Financials = 
    Financials { reportDate       :: String  -- ^ The report's date
               , grossProfit      :: Int     -- ^ Gross Profit
               , costOfRevenue    :: Int     -- ^ Cost of revenue
               , cashFlow         :: Int     -- ^ Cash flow
               } deriving (Show)

instance FromJSON Financials where
    parseJSON = withObject "Financials" $ \v -> Financials
        <$> v .: "reportDate"
        <*> v .: "grossProfit"
        <*> v .: "costOfRevenue"
        <*> v .: "cashFlow"

type Company = String

lowerString :: Company -> String
lowerString str = Prelude.map toLower str

baseURL :: String
baseURL = "https://api.iextrading.com/1.0/stock/"

data QueryType = QueryStocks
               | QueryFinancials
               | QueryPeers
               | QueryPrice

-- builds the URL: /stock/{symbol}/quote
stocksQuery :: Company -> String
stocksQuery company = baseURL ++ lowerString company ++ "/quote"

-- builds the URL: /stock/{symbol}/financials
financialsQuery :: Company -> String
financialsQuery company = baseURL ++ lowerString company ++ "/financials"

-- builds the URL: /stock/{symbol}/peers
peersQuery :: Company -> String
peersQuery company = baseURL ++ lowerString company ++ "/peers"

-- builds the URL: /stock/{symbol}/price
priceQuery :: Company -> String
priceQuery company = baseURL ++ lowerString company ++ "/price"

-- get JSON data 
getData :: (FromJSON a) => String -> QueryType -> IO (Maybe a)
getData company qt = do
    obj <- simpleHttp (query qt company)
    return $ decode obj
  where
    query QueryStocks     = stocksQuery
    query QueryFinancials = financialsQuery

-- Get non JSON data
getNonJSONData :: String -> QueryType -> IO ByteString
getNonJSONData company qt = do
    obj <- simpleHttp (query qt company)
    return obj
  where
    query QueryPeers = peersQuery
    query QueryPrice = priceQuery