from diagrams import Cluster, Diagram
from diagrams.onprem.compute import Server
from diagrams.onprem.database import PostgreSQL
from diagrams.onprem.network import Nginx

graph_attr = {
    "splines": "spline",
    "rankdir": "LR",
}

with Diagram(
    "Three-Tier Application Architecture",
    filename="docs/architecture",
    show=False,
    graph_attr=graph_attr,
):
    with Cluster("Web Tier - web-subnet 10.0.1.0/24"):
        web_1 = Nginx("web-01")
        web_2 = Nginx("web-02")

    with Cluster("Application Tier - app-subnet 10.0.2.0/24"):
        app_1 = Server("app-01")
        app_2 = Server("app-02")

    with Cluster("Database Tier - db-subnet 10.0.3.0/24"):
        database = PostgreSQL("PostgreSQL 14")

    web_1 >> app_1
    web_1 >> app_2
    web_2 >> app_1
    web_2 >> app_2

    app_1 >> database
    app_2 >> database
