import os
import sys
import json
import datetime
from pathlib import Path
from pip._internal import main
# install latest version of boto3
main(['install', '-I', '-q', 'boto3', '--target', '/tmp/', '--no-cache-dir', '--disable-pip-version-check'])
sys.path.insert(0, '/tmp/')
import boto3

# initialize redshift-data client in boto3
redshift_client = boto3.client("redshift-data")

def call_data_api(redshift_client, redshift_database, redshift_workgroup, sql_statement, with_event=True):
    # execute the input SQL statement - Serverless uses IAM auth automatically, no DbUser/SecretArn needed
    api_response = redshift_client.execute_statement(
        Database=redshift_database,
        Sql=sql_statement,
        WorkgroupName=redshift_workgroup,
        WithEvent=with_event
    )

    # return the query_id
    query_id = api_response["Id"]
    return query_id

def check_data_api_status(redshift_client, query_id):
    desc = redshift_client.describe_statement(Id=query_id)
    status = desc["Status"]

    if status == "FAILED":
        raise Exception('SQL query failed:' + query_id + ": " + desc["Error"])
    return status.strip('"')

def get_api_results(redshift_client, query_id):
    response = redshift_client.get_statement_result(Id=query_id)
    return response

def lambda_handler(event, context):
    redshift_wg_id = os.environ['redshift_workgroup']
    redshift_database = os.environ['redshift_database']

    action = event['queryStringParameters'].get('action')
    return_status = 200
    try:
        if action == "execute_report":
            country = event['queryStringParameters'].get('country_name')
            # sql report query to be submitted
            sql_statement = "select * from nation where n_name = '" + country + "'"
            api_response = call_data_api(redshift_client, redshift_database, redshift_wg_id, sql_statement)
            return_body = json.dumps(api_response)

        elif action == "check_report_status":
            query_id = event['queryStringParameters'].get('query_id')
            api_response = check_data_api_status(redshift_client, query_id)
            return_body = json.dumps(api_response)

        elif action == "get_report_results":
            query_id = event['queryStringParameters'].get('query_id')
            api_response = get_api_results(redshift_client, query_id)
            return_body = json.dumps(api_response)

            nrows = api_response["TotalNumRows"]
            ncols = len(api_response["ColumnMetadata"])
            print("Number of rows: %d , columns: %d" % (nrows, ncols))

            for record in api_response["Records"]:
                print(record)

        else:
            return_status = 500
            return_body = "Invalid Action: " + str(action)

        return_headers = {
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET"
        }
        return {'statusCode': return_status, 'headers': return_headers, 'body': return_body}

    except NameError as error:
        raise NameError(error)
    except Exception as exception:
        error_message = "Encountered exeption on:" + str(action) + ":" + str(exception)
        raise Exception(error_message)
    

    """
  // execute_event
    {
  "queryStringParameters": {
    "action": "execute_report",
    "country_name": "ALGERIA"
  }
}
// check_event
    for testing use the below test cases, 
    {
  "queryStringParameters": {
    "action": "check_report_status",
    "query_id": "paste the output query id from exeute_event result"
  }
}


  // output_event
    {
  "queryStringParameters": {
    "action": "get_report_results",
    "query_id": "46977c38-0e4e-46b0-a41c-dd27ca4136d6"
  }
}
    """