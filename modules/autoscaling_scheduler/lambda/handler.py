import boto3
import os

asg = boto3.client("autoscaling")
ecs = boto3.client("ecs")

ASG_NAME = os.environ["ASG_NAME"]
ECS_CLUSTER = os.environ["ECS_CLUSTER"]
ECS_SERVICE = os.environ["ECS_SERVICE"]

def lambda_handler(event, context):
    action = event.get("action")

    if action == "scale_down":
        asg.update_auto_scaling_group(
            AutoScalingGroupName=ASG_NAME,
            MinSize=0,
            DesiredCapacity=0,
            MaxSize=0
        )
        ecs.update_service(
            cluster=ECS_CLUSTER,
            service=ECS_SERVICE,
            desiredCount=0
        )
        return {"status": "scaled down"}

    elif action == "scale_up":
        asg.update_auto_scaling_group(
            AutoScalingGroupName=ASG_NAME,
            MinSize=int(os.environ["SCALE_UP_MIN_SIZE"]),
            DesiredCapacity=int(os.environ["SCALE_UP_DESIRED"]),
            MaxSize=int(os.environ["SCALE_UP_MAX_SIZE"])
        )
        ecs.update_service(
            cluster=ECS_CLUSTER,
            service=ECS_SERVICE,
            desiredCount=int(os.environ["SCALE_UP_ECS_COUNT"])
        )
        return {"status": "scaled up"}

    else:
        return {"status": "no action"}