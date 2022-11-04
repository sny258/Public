def metric():

  import os
  import base64
  import requests
  import json

  os.environ['AZP_URL'] = "https://dev.azure.com/snyverma1994"
  os.environ['AZP_POOL'] = "Default"
  os.environ['AZP_TOKEN'] = "hqp7xi75oa5yoe52squxmgsn46de56i6l3fk4rv2j7mefzgcdm7a"

  # print(os.environ['AZP_TOKEN'])
  # PAT_bytes = os.environ['AZP_TOKEN'].encode('ascii')
  # print(PAT_bytes)
  # PAT_base64_bytes = base64.b64encode(PAT_bytes)
  # print(PAT_base64_bytes)
  # PAT_base64_string = PAT_base64_bytes.decode('ascii')
  # print(PAT_base64_string)

  PAT_base64_string = str(base64.b64encode(bytes(':'+os.environ['AZP_TOKEN'], 'ascii')), 'ascii')

  PoolsUrl = os.environ['AZP_URL']+"/_apis/distributedtask/pools?api-version=5.1"
  #print(PoolsUrl)

  headers1 = {'Authorization': 'Basic %s' % PAT_base64_string}
  #headers1 = {'Authorization': 'Basic OmhxcDd4aTc1b2E1eW9lNTJzcXV4bWdzbjQ2ZGU1Nmk2bDNmazRydjJqN21lZnpnY2RtN2E='}
  #headers1 = {'Authorization': 'Basic aHFwN3hpNzVvYTV5b2U1MnNxdXhtZ3NuNDZkZTU2aTZsM2ZrNHJ2Mmo3bWVmemdjZG03YQ=='}
  #print(headers1)
  Pools = requests.get(PoolsUrl, headers=headers1).json()
  #print(Pools)
  #print(Pools['count'])
  for items in Pools['value']:
    #print(items['name'], items['id'])
    if items['name'] == os.environ['AZP_POOL']:
      print('AgentPool ID: '+str(items['id']))
      PoolId = items['id']

  # to get the online agents count in the AgentPool
  AgentsUrl = os.environ['AZP_URL']+"/_apis/distributedtask/pools/"+str(PoolId)+"/agents?api-version=5.1"
  #print(AgentsUrl)
  Agents = requests.get(AgentsUrl, headers=headers1).json()
  #print(Agents['value'])
  l1=[]
  for items in Agents['value']:
    #print(items['name'], items['id'])
    if items['status'] == 'online':
      #print('online Agent Id: '+ str(items['id']))
      l1.append(items['id'])
      #print(l1)
    Online_Agent_Count = len(l1)
    print('Online Agent Count: '+ str(Online_Agent_Count))

  # to get the the running jobs and queued jobs count
  jobsurl = os.environ['AZP_URL']+"/_apis/distributedtask/pools/"+str(PoolId)+"/jobrequests?api-version=5.1"
  jobs = requests.get(jobsurl, headers=headers1).json()
  #print(jobs)
  #print(jobs['value'])
  # if there is no finishTime, and also not receiveTime, then it is queued.
  l2=[]
  for items in jobs['value']:
    #print(items)  
    #print(items['requestId'])
    if (("finishTime" not in items) and ("receiveTime" not in items)):
      #print('yes')
      l2.append(items['requestId'])

  #print(l2)
  Queued_jobs_Count = len(l2)
  print('Queued job Count: '+ str(Queued_jobs_Count))

  # When there is no finishTime, but there is a receiveTime, it is running.
  l3=[]
  for items in jobs['value']:
    #print(items)  
    #print(items['requestId'])
    if (("finishTime" not in items) and ("receiveTime" in items)):
      #print('yes')
      l3.append(items['requestId'])

  #print(l3)
  Running_jobs_Count = len(l3)
  print('Running job Count: '+ str(Running_jobs_Count))

  #Custom metric
  Custom_Metric = Online_Agent_Count - Running_jobs_Count - Queued_jobs_Count
  print('Custom Metric: '+ str(Custom_Metric))
  str_Custom_Metric = str(Custom_Metric)
  return "Custom_Metric: "+str_Custom_Metric

# result=metric()
# print("Custom_Metric: "+result)