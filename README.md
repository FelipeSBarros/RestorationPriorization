# Restoration Function

Authors:  
Felipe Sodré Mendes Barros  
Renato Crouzeilles  
Julia Niemeyer  

Function in development in R to simulate restoration in different properties maximizing or minimizing different themes (e.g.: opportunity cost).

## 1. preAnalysis function  
  
Function developed to estimate amout of forest debt/credit in each property analysed, according to Brazilian Native Vegetation Law [12.651/12](http://www.planalto.gov.br/ccivil_03/_ato2011-2014/2012/lei/l12651.htm).
  
```
> source("restoration.function.R")
> args(preAnalysis)
function (forest_t = forest_t, 
appt = appt, 
car = carList[[4]],
restYears = 10)
```
  
#### preAnalysis input:  
  
* forest_t = Actual forest remnants (raster layer: 1 = forest; 0 = non forest; NA = non forest and non restorable sites [e.g.: Urban Areas] & areas outside the site of study);  
* appt = Area of Riparian Protection (Área de Proteção Permanente, in portuguese) (raster layer: 1 = Riparian areas; 0 = non riparian areas; NA = areas outside the site of study);  
* car = Rural Environmental Registry (Cadastro Ambiental Rural - CAR, in portuguese) (vector layer with property limits, with "ID" and "Car_modulo_fiscal" *fields*)  
* restYears = Number of years to be simulated in the analysis. This will change the amount to be restored yearly

#### preAnalysis output:  
  
Data frame:  

* car.area: Area of property
* f.total: Area of forest remnant
* app.area: Area of APP
* debt.app: Debit of APP (i.e.: Amount of pixels to be restored)
* rl.area: Area of Legal Reserve inside the property (discounting APP)
* debt.rl: Debit of Legal Reserve (in case of)
* credit.rl: Credit of Legal Reserve (in case of)
* TotalToRestore: Total amount to be restored (in pixels)
* ToRest2years: Total to be restored  (in pixels) considering 20 years of restoration and that the restoration will be done according to parameter `restYears`.
* Car.ID: Property ID
* Modu_Fisc: Property modulo fiscal
* obs: Observation about property: wether it is all forested, unforested, not_analized, ...  
  
```
head(debito)


---------------------------------------------------------------------------
 X   Car_ID   Car_modulo_fiscal   car.area   f.total   app.area   debt.app 
--- -------- ------------------- ---------- --------- ---------- ----------
 1     34            50             683        240        25         16    

 2     42            89             1212       546        49         15    

 3     43            75             1020       177       144        113    

 4     49            68             931        269        27         26    

 5     76             9             122        58         0          0     

 6     79            27             374        224        0          0     
---------------------------------------------------------------------------

Table: Table continues below

 
------------------------------------------------------------------------
          obs            rl.area   debt.rl   credit.rl   TotalToRestore 
----------------------- --------- --------- ----------- ----------------
Property with RL credit   111.6       0        119.4           16       

Property with RL credit   193.4       0        318.6           15       

Property with RL credit    60         0         86            113       

Property with RL credit   159.2       0        108.8           26       

Property with RL credit   24.4        0        33.6            0        

Property with RL credit   74.8        0        149.2           0        
------------------------------------------------------------------------

Table: Table continues below

 
-----------------
 ToRestore2years 
-----------------
        1        

        1        

       11        

        2        

        0        

        0        
-----------------
```

