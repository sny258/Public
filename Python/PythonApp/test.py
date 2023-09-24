def test():
    print("hello !!!")
    cm = "custom"+"metric"
    print(cm)
    return cm

y=test()
print(y)

#-------------------------

# import os
# import base64
# import requests
# import json

# os.environ['AZP_URL'] = "https://dev.azure.com/<org>"
# os.environ['AZP_POOL'] = "Default"
# os.environ['AZP_TOKEN'] = "<PAT>"

# PAT_base64_string = str(base64.b64encode(bytes(':'+os.environ['AZP_TOKEN'], 'ascii')), 'ascii')

# PoolsUrl = os.environ['AZP_URL']+"/_apis/distributedtask/pools?api-version=5.1"

# headers1 = {'Authorization': 'Basic %s' % PAT_base64_string}
# Pools = requests.get(PoolsUrl, headers=headers1).json()
# for items in Pools['value']:
#   #print(items['name'], items['id'])
#   if items['name'] == os.environ['AZP_POOL']:
#     print('AgentPool ID: '+str(items['id']))
#     PoolId = items['id']

# # to get the online agents count in the AgentPool
# AgentsUrl = os.environ['AZP_URL']+"/_apis/distributedtask/pools/"+str(PoolId)+"/agents?api-version=5.1"
# Agents = requests.get(AgentsUrl, headers=headers1).json()
# l1=[]
# for items in Agents['value']:
#   #print(items['name'], items['id'])
#   if items['status'] == 'online':
#     l1.append(items['id'])
#   Online_Agent_Count = len(l1)
#   print('Online Agent Count: '+ str(Online_Agent_Count))

# # to get the the running jobs and queued jobs count
# jobsurl = os.environ['AZP_URL']+"/_apis/distributedtask/pools/"+str(PoolId)+"/jobrequests?api-version=5.1"
# jobs = requests.get(jobsurl, headers=headers1).json()

# # if there is no finishTime, and also not receiveTime, then it is queued.
# l2=[]
# for items in jobs['value']:
#   if (("finishTime" not in items) and ("receiveTime" not in items)):
#     l2.append(items['requestId'])

# Queued_jobs_Count = len(l2)
# print('Queued job Count: '+ str(Queued_jobs_Count))

# # When there is no finishTime, but there is a receiveTime, it is running.
# l3=[]
# for items in jobs['value']:
#   if (("finishTime" not in items) and ("receiveTime" in items)):
#     l3.append(items['requestId'])

# Running_jobs_Count = len(l3)
# print('Running job Count: '+ str(Running_jobs_Count))


# #Custom metric
# Custom_Metric = Online_Agent_Count - Running_jobs_Count - Queued_jobs_Count
# print('Custom Metric: '+ str(Custom_Metric))