# %% 
# Dependencies 
import pandas as pd
import numpy as np 
import matplotlib as plt

# %%
# Declaring variables
x = 20
y = 10
z = 30

# %%
# Creating a DataFrame 
df = pd.DataFrame(
    {
        "variables": ["x","y","z"],
        "values": [x,y,z],
        "prod": [x*y,x*z,y*z]
    }
)