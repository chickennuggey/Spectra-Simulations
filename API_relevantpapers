import requests
import json
import pandas as pd
from iteration_utilities import unique_everseen

# query for articles including amorphous MoS3 OR EXAF (Note: up to 1000 papers returned in each call)
# query for articles including amorphous MoS3 AND EXAF
request_OR = requests.get("https://api.semanticscholar.org/graph/v1/paper/search/bulk?query=(amorphous+MoS3)|EXAF&fields=paperId,title,abstract,venue,year,authors&sort=publicationDate:desc")
request_AND = requests.get("https://api.semanticscholar.org/graph/v1/paper/search/bulk?query=amorphous+MoS3+EXAF&fields=paperId,title,abstract,venue,year,authors&sort=publicationDate:desc")

# convert to json
response_OR = request_OR.json()
response_AND = request_AND.json()

# loop through query to obtain ALL articles (since each request is restricted to 1000 articles at a time)
# Inputs: response is in json format, query is string

def extract_all(response, query):
  data = response["data"]
  token = response["token"]
  url = "https://api.semanticscholar.org/graph/v1/paper/search/bulk?query=" + query + "&fields=paperId,title,abstract,venue,year,authors&sort=publicationDate:desc&token="

  while(token != None):
      new_url = url + token
      response = requests.get(new_url)
      r_json = response.json()

      new_data = r_json["data"]
      data = data + new_data

      token = r_json["token"]

  return data

# extract all relevant papers
OR_data = extract_all(response_OR, "(amorphous+MoS3)|EXAF")
AND_data = extract_all(response_AND, "amorphous+MoS3+EXAF")

# extract unique papers
data = OR_data + AND_data
unique_data=list(unique_everseen(data))

# convert and save dataframe
df = pd.DataFrame(unique_data)
df.to_csv('relevantpapers.csv')
