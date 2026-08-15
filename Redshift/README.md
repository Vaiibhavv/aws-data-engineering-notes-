* How to improve the performence of the copy command 

# Quick Summary 

![alt text](image-11.png)
- load the multiple files at a time 

![alt text](image.png)

- Number of files equal to the number of slices 

![alt text](image-1.png)

- compress the data file 

![alt text](image-2.png)

- use the delimeted files

![alt text](image-3.png)

- using data distribution 

![alt text](image-4.png)

- use sort key 

![alt text](image-5.png)

- use the manifest file 

![alt text](image-6.png)

- keep computeupdate and statusupdte as off 

![alt text](image-7.png)

- adjust the copy command options

![alt text](image-8.png)

- preprocess the data before loading

![alt text](image-9.png)

- optimize network performence , do not use cross region queries

![alt text](image-10.png)


## How to connect the Redshift Warehouse with Lambda function

 1. Step 1: Create a Redshift cluster and configure the security group to allow access from your Lambda function.
 2. Step 2: Create an IAM role for your Lambda function with the necessary permissions to access Redshift. Also provide the inline policy to allow access to the Redshift cluster.

    ![alt text](image-12.png)

3. Step 3: Create a Lambda function and attach the IAM role created in step 2. Use the AWS SDK for Python (Boto3) to connect to the Redshift cluster and execute SQL queries.

4. 