# End-to-End Car Sales Data Pipeline on Azure

## 🚀 Project Overview

In this project, I implemented a complete, end-to-end data engineering pipeline on Microsoft Azure. I designed and built a system that ingests raw data from a GitHub repository, processes it through a multi-layered data lake using a medallion architecture, and models it into a star schema. All data assets are governed through Unity Catalog, and the final analytical model is stored in the efficient Delta Lake format. The core of this project is a custom, automated framework for handling incremental updates in the dimension tables using surrogate keys.



---

## 🛠️ Architecture & Technologies Used

![deproj_san](https://github.com/user-attachments/assets/5dc17075-2567-4ba4-b3ca-1ba3c54721aa)

* **Data Source:** GitHub Repository
* **Data Ingestion:** Azure Data Factory (ADF)
* **Data Storage & Format:** Azure SQL Database, Azure Data Lake Storage (ADLS) Gen2, **Delta Lake**
* **Data Processing & Transformation:** Azure Databricks (PySpark, Spark SQL)
* **Data Governance & Cataloging:** **Unity Catalog**
* **Security & Access:** Azure Databricks Access Connector, Managed Identities
* **Cloud Platform:** Microsoft Azure (Azure for Students Subscription)

---

## 📁 Azure Resource Organization

<img width="1919" height="879" alt="Screenshot 2025-09-07 212044" src="https://github.com/user-attachments/assets/ecdcf88c-f335-4107-b699-e21761899971" />

I organized all the primary Azure services for this project, including Azure Data Factory, ADLS Gen2, and the Azure SQL Server, within a dedicated resource group named `RG_car_project`. As part of the Databricks workspace setup, a separate, managed resource group (`managed_car_project`) was automatically provisioned to house the cluster-related resources.

resources:
<img width="1765" height="815" alt="Screenshot 2025-09-07 201350" src="https://github.com/user-attachments/assets/d61512d2-24f6-4ef4-a4ad-1247b9a8e507" />



---

## ⚙️ Project Implementation

### Phase 1: Data Ingestion & Staging (Azure Data Factory)

I created two pipelines in ADF to manage the flow of data from the source to the initial landing zone.

linked services:
<img width="1919" height="928" alt="image" src="https://github.com/user-attachments/assets/65f12496-789d-412a-8b20-a20cd767b7b5" />


* **Initial Load (`source_prep` pipeline):**
<img width="1913" height="912" alt="image" src="https://github.com/user-attachments/assets/f1141da2-dae4-469d-baac-e0eb7dcd2855" />

I built a Copy Activity to perform the initial, full load of the source data from GitHub directly into a table in an Azure SQL Database.

* **Incremental Load (`incremental_data_pipeline` pipeline):**
<img width="1919" height="919" alt="image" src="https://github.com/user-attachments/assets/29cf4e59-f7e1-40ec-94e7-5f71b8f10e9e" />

  To handle ongoing updates, I engineered a pipeline to copy only new data from the SQL database to the ADLS Gen2 bronze container.                                                                                                                                                                                                                                                                                    
* **Watermarking:** I implemented a robust watermarking technique by creating a dedicated table in Azure SQL to store the `last_load` date ID.                                                                                                        
* **Pipeline Logic:** The pipeline uses two Lookup activities to find the last loaded ID and the current maximum ID in the source. A Copy Activity then uses a dynamic query to pull only the records within that range.                                                                                                                                                              
* **Automation:** Finally, a Stored Procedure Activity updates the watermark table with the new maximum ID, ensuring the next run is seamless and accurate.

### Phase 2: Data Transformation & Modeling (Azure Databricks)

![star_schema](https://github.com/user-attachments/assets/d3a6d556-0d73-4656-8edf-22dcef9c6ab9)


This phase focuses on processing the data and building the final, comprehensive star schema, with all tables governed by Unity Catalog.

#### Gold Layer Modeling
* **Dimension Tables:** I developed a series of notebooks to build out the full set of dimension tables. I created four distinct dimensions: `dim_branch`, `dim_date`, `dim_dealer`, and `dim_model`.
* **Fact Table:** The final modeling step was to construct the central `fact_sales` table. This notebook joins the cleaned silver data with all four of the newly created dimension tables on their respective surrogate keys.
* All final tables in the gold layer were written to ADLS Gen2 as **Delta tables**, enabling ACID transactions and performance optimizations. These tables were registered in and governed by the **Unity Catalog** metastore.

#### Custom Incremental Processing (SCD Type 1)
To keep the dimension tables up-to-date without reprocessing the entire dataset, I implemented a custom incremental update framework.
* **Identifying New Records:** The logic reads distinct business keys from the silver layer and joins them with the keys in the existing gold dimension table. A left join allows me to isolate new records.
* **Surrogate Key Generation:** For these new records, I generated unique surrogate keys by finding the max existing key and incrementing from there. An `incremental_flag` parameter was used to handle the logic for the initial run versus subsequent updates.
* **Efficient Updates with Delta MERGE:** I used Delta Lake's `MERGE` command to efficiently upsert the data into the dimension tables, inserting new records (`whenNotMatchedInsertAll`) and updating existing ones (`whenMatchedUpdateAll`).

#### Orchestration (Databricks Jobs)

<img width="681" height="317" alt="Screenshot 2025-09-07 200913" src="https://github.com/user-attachments/assets/d8fffe23-2eec-4f69-9e2a-69391bcdcac4" />

I automated the entire transformation workflow using a Databricks job, which runs the dimension-building notebooks in parallel before executing the final `FACT_SALES` notebook.

---

## 🚧 Challenges Faced & Solutions

### In Azure Data Factory
* **SQL Connectivity:** During the initial setup, my ADF pipeline failed to connect to the Azure SQL Server.                                                                                                                                                              

  **Solution:** I diagnosed this as a firewall issue and **resolved it by enabling the "Allow Azure services and resources to access this server"** setting in the SQL Server's networking panel.

### In Azure & Databricks
* **Subscription & Region Limitations:** My initial resource deployment failed due to Azure for Students subscription restrictions.

  **Solution:** I researched supported regions, selected **Central India**, and successfully redeployed all resources.
  
* **Cluster Creation:** I was unable to create a standard cluster due to policy restrictions.                                                                                                                    

   **Solution:** I identified a compatible node type (**`Standard_D4s_v3`**) that worked within the subscription's core limits.
  
* **Unity Catalog Permissions:** I was unable to create catalogs and schemas,error saying i don't have permission                                                                                                                                                                                          

  **Solution:** I fixed permission errors by correcting the Metastore Admin assignment from my personal email to the proper Entra ID user, which resolved access issues.
