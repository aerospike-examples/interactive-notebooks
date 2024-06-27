import re
import csv 
import json
import nest_asyncio
import ipycytoscape
import pandas as pd
import networkx as nx
import ipywidgets as widgets
import matplotlib.pyplot as plt
import numpy as np
#import pydantic
#from pydantic.v1 import BaseModel
#from pydantic_settings import BaseSettings 
#from pandas_profiling import ProfileReport
#from ydata_profiling import ProfileReport
import seaborn as sns
from scipy.stats import norm
from scipy import stats
import warnings
warnings.filterwarnings('ignore')
plt.style.use('bmh')

# Gremlin Packages
from gremlin_python.process.traversal import IO
from aerospike import exception as ex
from gremlin_python.process.anonymous_traversal import traversal
from gremlin_python.driver.driver_remote_connection import DriverRemoteConnection
from gremlin_python.process.graph_traversal import GraphTraversalSource, __
from gremlin_python.process.traversal import Barrier, Bindings, Cardinality, Column, Direction, Operator, Order, P, Pop, Scope, T, WithOptions
from gremlin_python.process.graph_traversal import __ as AnonymousTraversal
from gremlin_python import statics
statics.load_statics(globals())
values = AnonymousTraversal.values

# Other packages
from graph_fmt import *
from pprint import pprint, PrettyPrinter
from ipywidgets import interact
from IPython.display import display_markdown
from IPython.display import Markdown as md, display, HTML     # requires @jupyterlab/celltags extension
from ipywidgets import interact, interact_manual, AppLayout, Button, GridspecLayout
nest_asyncio.apply()

def display_dist(graph_stats):
    v_cnt = pd.DataFrame(columns=['vertex name', 'count'])
    for k, v in graph_stats.vertex_count_per_label.values.tolist()[0][0].items():
        v_cnt.loc[len(v_cnt)] = [k, v]
    e_cnt = pd.DataFrame(columns=['edge name', 'count'])
    for k, v in graph_stats.edge_count_per_label.values.tolist()[0][0].items():
        e_cnt.loc[len(e_cnt)] = [k, v]
    #define subplot layout
    fig, axes = plt.subplots(nrows=1, ncols=2, figsize=(20,5))
    ax1 = v_cnt.sort_values(by = 'count', ascending=False,).plot.bar(ax=axes[0], title='Vertex Counts', x='vertex name', rot=50, color = 'red')
    ax1.set_ylabel("vertices Count")
    ax1.bar_label(ax1.containers[0])
    ax2 = e_cnt.sort_values(by = 'count', ascending=False,).plot.bar(ax=axes[1], title='Edge Counts',x='edge name', rot=50, color = 'green')
    ax2.set_ylabel("edges Count")
    ax2.bar_label(ax2.containers[0])
    return plt.show()

def display_graph(vertices_list, edge_list):
    netGraph = '{\n  "nodes": [\n'
    for row in range(len(vertices_list)):
        if row == 0:
            netGraph = netGraph + '{"data": {"id":"' + str(vertices_list[row][0]) + '", "label":"persons", "classes":"person"}}\n'
        else:
            netGraph = netGraph + ',{"data": {"id":"' + str(vertices_list[row][0]) + '", "label":"persons", "classes":"person"}}\n'
    df = pd.DataFrame(edge_list, columns=['PersonVertices', 'RelationshipValue', 'EdgeType'])
    df = df.astype(str)
    df['EdgeType'] = df['EdgeType'].str.replace(r'^.* \'(.*)\'}', '\\1', regex=True)
    df = df.astype(str).sort_values(by=['RelationshipValue'])
    df = df.query("EdgeType in ['has_last_name', 'lives_in', 'used_ip_address', 'used_device', 'in_zipcode', 'in_city', 'has_phone']")
    result = df.groupby(['RelationshipValue', 'EdgeType']).count()
    for i, row in result.iterrows():
        match i[1]:
            case 'has_last_name':
                netGraph = netGraph + ',{"data": {"id":"' + str(i[0]) + '", "label":"last_name", "classes":"last_name"}}\n'
            case 'lives_in':
                netGraph = netGraph + ',{"data": {"id":"' + str(i[0]) + '", "label":"address", "classes":"address"}}\n'
            case 'used_ip_address':
                netGraph = netGraph + ',{"data": {"id":"' + str(i[0]) + '", "label":"ip_address", "classes":"ip_address"}}\n'
            case 'used_device':
                netGraph = netGraph + ',{"data": {"id":"' + str(i[0]) + '", "label":"device", "classes":"device"}}\n'
            case 'in_zipcode':
                netGraph = netGraph + ',{"data": {"id":"' + str(i[0]) + '", "label":"zipcode", "classes":"zipcode"}}\n'
            case 'in_city':
                netGraph = netGraph + ',{"data": {"id":"' + str(i[0]) + '", "label":"city", "classes":"city"}}\n'
            case 'has_phone':
                netGraph = netGraph + ',{"data": {"id":"' + str(i[0]) + '", "label":"phone", "classes":"phone"}}\n'
            case _:
                print('ELSE')
            
    netGraph = netGraph + '],\n"edges": [\n'         
    for i, row in df.sort_index().iterrows():
        match row[2]:
            case 'has_last_name':
                if i == 0:
                    netGraph = netGraph + '{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
                else:
                    netGraph = netGraph + ',{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
            case 'lives_in':
                if i == 0:
                    netGraph = netGraph + '{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
                else:
                    netGraph = netGraph + ',{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
            case 'used_ip_address':
                if i == 0:
                    netGraph = netGraph + '{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
                else:
                    netGraph = netGraph + ',{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
            case 'used_device':
                if i == 0:
                    netGraph = netGraph + '{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
                else:
                    netGraph = netGraph + ',{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
            case 'in_zipcode':
                if i == 0:
                    netGraph = netGraph + '{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
                else:
                    netGraph = netGraph + ',{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
            case 'in_city':
                if i == 0:
                    netGraph = netGraph + '{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
                else:
                    netGraph = netGraph + ',{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
            case 'has_phone':
                if i == 0:
                    netGraph = netGraph + '{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
                else:
                    netGraph = netGraph + ',{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
            case _:
                print('ELSE')
            
    netGraph = netGraph + '  ]\n}'

    my_style = [
        {'selector': 'node','style': {
            'font-family': 'arial',
            'font-size': '10px',
            'label': 'data(label)',}}, 
        {'selector': 'node[classes="person"]','style': {
           'background-color': 'yellow'}},
        {'selector': 'node[classes="last_name"]','style': {
            'font-family': 'arial',
            'font-size': '10px',
            'label': 'data(id)',
          'background-color': '#B9DFE0'}},
        {'selector': 'node[label = "persons"]','style': {
            'font-family': 'arial',
            'font-size': '10px',
            'label': 'data(id)',
            'text-valign': 'center',
            'width': '50px',
            'height': '50px',
            'background-color': '#EDEDED'}},
        {'selector': 'node[label = "ip_address"]','style': {
            'font-family': 'arial',
            'font-size': '10px',
            'label': 'data(id)',
            'background-color': '#E5C3DC'}},
        {'selector': 'node[label = "device"]','style': {
            'font-family': 'arial',
            'font-size': '10px',
            'label': 'data(id)',
            'background-color': '#D0C6E2'}},
        {'selector': 'node[label = "phone"]','style': {
            'font-family': 'arial',
            'font-size': '10px',
            'label': 'data(id)',
            'background-color': '#D3DAE0'}},
        {'selector': 'node[label = "address"]','style': {
            'font-family': 'arial',
            'font-size': '10px',
            'label': 'data(id)',
            'background-color': '#E0DEDC'}},
        {'selector': 'node[label = "zipcode"]','style': {
            'font-family': 'arial',
            'font-size': '10px',
            'label': 'data(id)',
            'background-color': '#E4C7C6'}},
        {'selector': 'node[label = "city"]','style': {
            'font-family': 'arial',
            'font-size': '10px',
            'label': 'data(id)',
            'background-color': '#B0E136'}},
        {'selector': 'edge','style': {
            'font-family': 'arial',
            'font-size': '10px',
            'label': 'data(label)'}},
    ]
    
    railnetJSON = json.loads(netGraph)
    ipycytoscape_obj9 = ipycytoscape.CytoscapeWidget()
    ipycytoscape_obj9.graph.add_graph_from_json(railnetJSON, directed=True) # I am telling I dont want directions
    ipycytoscape_obj9.set_style(my_style)
    return ipycytoscape_obj9

def display_graph2(vertices_list, edge_list):
    netGraph = '{\n  "nodes": [\n'
    for row in range(len(vertices_list)):
        if row == 0:
            netGraph = netGraph + '{"data": {"id":"' + str(vertices_list[row][0]) + '", "label":"persons", "classes":"person"}}\n'
        else:
            netGraph = netGraph + ',{"data": {"id":"' + str(vertices_list[row][0]) + '", "label":"persons", "classes":"person"}}\n'
    df = pd.DataFrame(edge_list, columns=['PersonVertices', 'RelationshipValue', 'EdgeType'])
    df = df.astype(str)
    df['EdgeType'] = df['EdgeType'].str.replace(r'^.* \'(.*)\'}', '\\1', regex=True)
    df = df.astype(str).sort_values(by=['RelationshipValue'])
    df = df.query("EdgeType in ['viewed', 'used_ip_address', 'used_device']")
    result = df.groupby(['RelationshipValue', 'EdgeType']).count()
    for i, row in result.iterrows():
        match i[1]:
            case 'viewed':
                netGraph = netGraph + ',{"data": {"id":"' + str(i[0]) + '", "label":"videos", "classes":"last_name"}}\n'
            case 'used_ip_address':
                netGraph = netGraph + ',{"data": {"id":"' + str(i[0]) + '", "label":"ip_addresse", "classes":"ip_address"}}\n'
            case 'used_device':
                netGraph = netGraph + ',{"data": {"id":"' + str(i[0]) + '", "label":"device", "classes":"device"}}\n'
            case _:
                print('ELSE')
            
    netGraph = netGraph + '],\n"edges": [\n'         
    for i, row in df.sort_index().iterrows():
        match row[2]:
            case 'viewed':
                if i == 0:
                    netGraph = netGraph + '{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
                else:
                    netGraph = netGraph + ',{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
            case 'used_ip_address':
                if i == 0:
                    netGraph = netGraph + '{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
                else:
                    netGraph = netGraph + ',{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
            case 'used_device':
                if i == 0:
                    netGraph = netGraph + '{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
                else:
                    netGraph = netGraph + ',{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
            case _:
                print('ELSE')
            
    netGraph = netGraph + '  ]\n}'

    my_style = [
        {'selector': 'node','style': {
            'font-family': 'arial',
            'font-size': '10px',
            'label': 'data(label)',}}, 
        {'selector': 'node[classes="person"]','style': {
            'background-color': 'yellow'}},
        {'selector': 'node[label = "ip_address"]','style': {
            'font-family': 'arial',
            'font-size': '10px',
            'label': 'data(id)',
            'background-color': '#E5C3DC'}},
        {'selector': 'node[label = "device"]','style': {
            'font-family': 'arial',
            'font-size': '10px',
            'label': 'data(id)',
            'background-color': '#D0C6E2'}},
        {'selector': 'edge','style': {
            'font-family': 'arial',
            'font-size': '10px',
            'label': 'data(label)'}},
    ]
    
    railnetJSON = json.loads(netGraph)
    ipycytoscape_obj9 = ipycytoscape.CytoscapeWidget()
    ipycytoscape_obj9.graph.add_graph_from_json(railnetJSON, directed=True) # I am telling I dont want directions
    ipycytoscape_obj9.set_style(my_style)
    return ipycytoscape_obj9

def display_graph3(vertices_list, edge_list):
    netGraph = '{\n  "nodes": [\n'
    for row in range(len(vertices_list)):
        if row == 0:
            netGraph = netGraph + '     {"data": {"id":"' + vertices_list[row][0] + '", "label": "' + vertices_list[row][0] + '"}}\n'
        else:
            netGraph = netGraph + '    ,{"data": {"id":"' + vertices_list[row][0] + '", "label": "' + vertices_list[row][0] + '"}}\n'
    display(vertices_list)
    df = pd.DataFrame(edge_list, columns=['Vertices', 'RelationshipValue', 'EdgeType'])
    df = df.astype(str)
    df['EdgeType'] = df['EdgeType'].str.replace(r'^.* \'(.*)\'}', '\\1', regex=True)
    df = df.astype(str).sort_values(by=['RelationshipValue'])
    df = df.query("EdgeType in ['has_identification', 'has_signalid', 'has_account', 'has_emailaddress','has_phone','has_phone']")
    result = df.groupby(['RelationshipValue', 'EdgeType']).count()
    for i, row in result.iterrows():
        match i[1]:
            case 'has_identification':
                netGraph = netGraph + ',{"data": {"id":"' + str(i[0]) + '", "label":"has_identification", "classes":"has_identification"}}\n'
            case 'has_signalid':
                netGraph = netGraph + ',{"data": {"id":"' + str(i[0]) + '", "label":"has_signalid", "has_signalid":"has_signalid"}}\n'
            case 'has_account':
                netGraph = netGraph + ',{"data": {"id":"' + str(i[0]) + '", "label":"has_account", "has_account":"has_account"}}\n'
            case 'has_emailaddress':
                netGraph = netGraph + ',{"data": {"id":"' + str(i[0]) + '", "label":"has_emailaddress", "has_emailaddress":"has_emailaddress"}}\n'
            case 'has_phone':
                netGraph = netGraph + ',{"data": {"id":"' + str(i[0]) + '", "label":"has_phone", "has_phone":"has_phone"}}\n'
            case _:
                print('ELSE')
            
    netGraph = netGraph + '],\n"edges": [\n'         
    for i, row in df.sort_index().iterrows():
        match row[2]:
            case 'has_identification':
                if i == 0:
                    netGraph = netGraph + '{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
                else:
                    netGraph = netGraph + ',{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
            case 'has_signalid':
                if i == 0:
                    netGraph = netGraph + '{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
                else:
                    netGraph = netGraph + ',{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
            case 'has_account':
                if i == 0:
                    netGraph = netGraph + '{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
                else:
                    netGraph = netGraph + ',{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
            case 'has_emailaddress':
                if i == 0:
                    netGraph = netGraph + '{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
                else:
                    netGraph = netGraph + ',{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
            case 'has_phone':
                if i == 0:
                    netGraph = netGraph + '{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
                else:
                    netGraph = netGraph + ',{"data": { "id": "line' + str(i) + '", "source": "' + row[0] + '", "target": "' + row[1] + '","label":"' + row[2] + '"}}\n'
            case _:
                print('ELSE')
            
    netGraph = netGraph + '  ]\n}'
    
    colors = ['#E5C3DC', '#D0C6E2', '#D3DAE0', '#E0DEDC', '#E4C7C6', '#B0E136', '#8293C4', '#CCDF0B'
        , '#DFBE6E', '#EC7924', '#ECBFDD', '#BFBFEC', '#10B6EC', '#A2ECA4', '#EC3E17', '#2C52EC']

    my_style = [
        {'selector': 'node','style': {
            'font-family': 'arial',
            'font-size': '8px',
            'label': 'data(label)',
            'background-color': 'red'}},
        {'selector': 'node[label = "OBSERVATIONS"]','style': {
            'font-family': 'arial',
            'font-size': '8px',
            'label': 'data(id)',
            'width': '50px',
            'height': '50px',
            'background-color': '#E5C3DC'}},
        {'selector': 'node[label = "ACCOUNTS_INFO"]','style': {
            'font-family': 'arial',
            'font-size': '8px',
            'label': 'data(id)',
            'background-color': '#D0C6E2'}},
        {'selector': 'node[label = "EMAILS"]','style': {
            'font-family': 'arial',
            'font-size': '8px',
            'label': 'data(id)',
            'background-color': '#D3DAE0'}},
        {'selector': 'node[label = "IDENTIFICATIONS"]','style': {
            'font-family': 'arial',
            'font-size': '8px',
            'label': 'data(id)',
            'background-color': '#E0DEDC'}},
        {'selector': 'node[label = "SIGNALIDS"]','style': {
            'font-family': 'arial', 
            'font-size': '8px',
            'label': 'data(id)',
            'background-color': '#E4C7C6'}},
        {'selector': 'node[label = "STD_ADDRESSES"]','style': {
            'font-family': 'arial',
            'font-size': '8px',
            'label': 'data(id)',
            'background-color': '#B0E136'}},
        {'selector': 'node[label = "TAXID_NUMBERS"]','style': {
            'font-family': 'arial',
            'font-size': '8px',
            'label': 'data(id)',
            'background-color': '#8293C4'}},
        {'selector': 'node[label = "TELEPHONES"]','style': {
            'font-family': 'arial',
            'font-size': '8px',
            'label': 'data(id)',
            'background-color': '#CCDF0B'}},
        {'selector': 'node[classes="has_identification"]','style': {
            'font-family': 'arial',
            'font-size': '10px',
            'label': 'data(id)',
            'background-color': '#B9DFE0'}},
        {'selector': 'node[classes="has_signalid"]','style': {
            'font-family': 'arial',
            'font-size': '10px',
            'label': 'data(id)',
            'background-color': '#B9DFE0'}},
        {'selector': 'edge','style': {
            'font-family': 'arial',
            'font-size': '10px',
            'label': 'data(label)'}},
    ]
    
    railnetJSON = json.loads(netGraph)
    ipycytoscape_obj9 = ipycytoscape.CytoscapeWidget()
    ipycytoscape_obj9.graph.add_graph_from_json(railnetJSON, directed=True) # I am telling I dont want directions
    ipycytoscape_obj9.set_style(my_style)
    return ipycytoscape_obj9

def dgraph_sch(graph_stats, g):
    pd.set_option('display.max_colwidth', None)
    colors =['#E5C3DC','#D0C6E2','#D3DAE0','#E0DEDC','#E4C7C6','#B0E136','#8293C4','#CCDF0B','#DFBE6E','#EC7924','#ECBFDD','#BFBFEC','#10B6EC','#A2ECA4','#EC3E17','#2C52EC', '#8EB387', '#738DB3', '#988CB3', '#E1BE93', '#90F013', '#60BE9D', '#B4BE9D', '#69E2D3', '#A7D0F7','#EBE0C9']

    vrtx_lbls = []
    for k, v in graph_stats.vertex_count_per_label.values.tolist()[0][0].items():
        vrtx_lbls.append(k)
    clr_idx = 0
    schema = '{\n  "nodes": [\n'
    grph_style = "[{'selector': 'any','style': {'content': 'data(name)'\n,'label': 'data(label)'\n,'font-size': '25px'\n,'background-color': 'blue'}}\n,{'selector': 'node'\n,'style': {'content': 'data(name)'\n,'label': 'data(label)'\n,'width': '95px','height': '95px'}},\n"
    for row in range(len(vrtx_lbls)):
        if clr_idx < len(colors):
            clr_idx += 1
        else:
            clr_idx=0
        if row == 0:
            schema = schema + '     {"data": {"id":"' + vrtx_lbls[row] + '", "label": "' + vrtx_lbls[row] + '"}}\n'
        else:
            schema = schema + '    ,{"data": {"id":"' + vrtx_lbls[row] + '", "label": "' + vrtx_lbls[row] + '"}}\n'
        grph_style = grph_style + "{'selector': 'node[label = \""\
            + vrtx_lbls[row] + "\"]'\n,'style': {'font-family': 'arial'\n, "\
            + "'font-size': '10px'\n, 'label': 'data(id)'\n, 'width': '50px'\n, 'height': '50px'\n, 'background-color': '"\
            + colors[clr_idx] + "'}},\n"
    schema = schema + '    ],\n  "edges": [\n'
    edg_lbls = []
    for k, v in graph_stats.edge_count_per_label.values.tolist()[0][0].items():
        edg_lbls.append(k)
    r = 0   
    for row in range(len(edg_lbls)):
        l = g.E().hasLabel(edg_lbls[row]).bothV().limit(5).label().limit(2).toList()
        if row == 0:
            schema = schema + '     {"data": {"id": "line' + str(row) + '", "source": "' + l[0] + '", "target": "' + l[1] + '", "label": "' + edg_lbls[row] + '"}}\n'
        else:
            schema = schema + '    ,{"data": {"id": "line' + str(row) + '", "source": "' + l[0] + '", "target": "' + l[1] + '", "label": "' + edg_lbls[row] + '"}}\n'
        r+=1
    schema = schema + '    ]\n}'
    grph_style = grph_style + "{'selector': 'edge','style': {'font-family': 'arial'\n, 'font-size': '10px',\n'label': 'data(label)'}},]"
    schmJSON = json.loads(schema)
    ipycytoscape_obj8 = ipycytoscape.CytoscapeWidget()
    ipycytoscape_obj8.graph.add_graph_from_json(schmJSON, directed=True)        # I am telling I dont want directions
    my_style=list(eval(grph_style))                                             # Convert the string to a Python List
    ipycytoscape_obj8.set_style(my_style)
    return ipycytoscape_obj8

def ews_grph(cname, g):
    df = pd.DataFrame()
    colors = ['#E5C3DC','#D0C6E2','#D3DAE0','#E0DEDC','#E4C7C6','#B0E136','#8293C4','#CCDF0B','#DFBE6E','#EC7924','#ECBFDD','#BFBFEC','#10B6EC','#A2ECA4','#EC3E17','#2C52EC', '#8EB387', '#738DB3', '#988CB3', '#E1BE93', '#90F013', '#60BE9D', '#B4BE9D', '#69E2D3', '#A7D0F7','#EBE0C9']
    p_set = g.V().has('OBSERVATIONS','cust_name', cname)\
             .outE('has_emailaddress', 'has_signalid', 'has_taxid_number', 'has_std_address', 'has_phone', 'has_account', 'has_identification').path().toList()
    lst = []

    pattern = re.compile(r'.*?\]\[(.*?)-(.*?)->(.*?)\]\]')
    for p in p_set:
        lst.append(pattern.sub('\\1\t\\2\t\\3',str(p)).split('\t'))   
        df = pd.DataFrame(lst, columns=['Customer_Name', 'Relationship', 'Value'])

    schema = '{\n  "nodes": [\n      {"data": {"id":"' + cname + '", "label": "' + cname + '"}}\n'
    tmp_str = "[{'selector': 'any','style': {'content': 'data(name)','label': 'data(label)','font-size': '25px','background-color': 'blue'}},{'selector':   'node','style': {'content': 'data(name)','label': 'data(label)','width': '95px','height': '95px'}}"
    for i, j in df.iterrows():
        schema = schema + '     ,{"data": {"id":"' + j['Value'] + '", "label": "' + j['Value'] + '"}}\n'
    schema = schema + '    ],\n  "edges": [\n'
    r = 0
    c = 1
    prev_chng = ''
    for i, j in df.iterrows():
        if r == 0:
            schema = schema + '     {"data": {"id": "line' + str(r) + '", "source": "' + cname + '", "target": "' + j['Value'] + '", "label": "' + j['Relationship'] + '"}}\n'
        else:
            schema = schema + '    ,{"data": {"id": "line' + str(r) + '", "source": "' + cname + '", "target": "' + j['Value'] + '", "label": "' + j['Relationship'] + '"}}\n'
        r+=1
        if prev_chng != j['Relationship']:
            c+=1
            tmp_str = tmp_str + ",{'selector': 'node[label = \"" + j['Value'] + "\"]','style': {'font-family': 'arial','font-size': '25px','label': 'data(id)','width': '100px','height': '100px','background-color': '" + colors[c] + "'}}" 
            match j['Relationship']:
                case 'has_emailaddress':
                    prev_chng = j['Relationship']
                case 'has_signalid':
                    prev_chng = j['Relationship']
                case 'has_taxid_type':
                    prev_chng = j['Relationship']
                case 'has_taxid_number':
                    prev_chng = j['Relationship']
                case 'has_std_address':
                    prev_chng = j['Relationship']
                case 'has_phone':
                    prev_chng = j['Relationship']
                case 'has_account':
                    prev_chng = j['Relationship']
                case 'has_identification':
                    prev_chng = j['Relationship']
                case _:
                    print('AICA!!!')
        else:
            tmp_str = tmp_str + ",{'selector': 'node[label = \"" + j['Value'] + "\"]','style': {'font-family': 'arial','font-size': '25px','label': 'data(id)','width': '100px','height': '100px','background-color': '" + colors[c] + "'}}" 

    schema = schema + '    ]\n}'
    tmp_str = tmp_str + ']'
    schmJSON = json.loads(schema)
    my_style=list(eval(tmp_str))                                             # Convert the string to a Python List
    ipycytoscape_obj8 = ipycytoscape.CytoscapeWidget()
    ipycytoscape_obj8.graph.add_graph_from_json(schmJSON, directed=True)      # I am telling I dont want the edge direction
    ipycytoscape_obj8.set_style(my_style)
    return ipycytoscape_obj8