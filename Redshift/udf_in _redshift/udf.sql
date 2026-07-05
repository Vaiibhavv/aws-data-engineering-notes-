--syntax

CREATE [ OR REPLACE ] FUNCTION f_function_name
( { [py_arg_name  py_arg_data_type |
sql_arg_data_type } [ , ... ] ] )
RETURNS data_type
{ VOLATILE | STABLE | IMMUTABLE }
AS $$
  { python_program | SELECT_clause }
$$ LANGUAGE { plpythonu | sql }

-- for more info- read the official doc- https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_FUNCTION.html

-- why to use udf- https://www.google.com/search?q=why+to+use+udf+in+aws+redshift&sca_esv=56474d3bad364ae4&sxsrf=APpeQnthhKOmRHiCIgQBebSfHm8yLDIr8g%3A1783245950215&ei=fixKar6yDLXf4-EPuKWe8QQ&ved=0ahUKEwi-6aLrpLuVAxW17zgGHbiSJ04Q4dUDCBI&uact=5&oq=why+to+use+udf+in+aws+redshift&gs_lp=Egxnd3Mtd2l6LXNlcnAiHndoeSB0byB1c2UgdWRmIGluIGF3cyByZWRzaGlmdDIIEAAYgAQYogQyBRAAGO8FMggQABiJBRiiBDIIEAAYiQUYogQyBRAAGO8FSNTpAVDyyAFY1OIBcAJ4AJABAZgBwRSgAf0uqgELMi01LjUuMS45LTG4AQPIAQD4AQGYAgegAqgLwgIKEAAYRxjWBBiwA8ICBxAjGLACGCeYAwCIBgGQBgiSBwcyLjAuMy4yoAf7KLIHBTItMy4yuAegC8IHBTAuNi4xyAcNgAgB&sclient=gws-wiz-serp

--python udf

create function f_py_greater (a float, b float)
  returns float
stable
as $$
  if a > b:
    return a
  return b
$$ language plpythonu;

select f_py_greater (l_extendedprice, l_discount) from lineitem limit 10

--SQL UDF

create function f_py_greater (a float, b float)
  returns float
stable
as $$
  if a > b:
    return a
  return b
$$ language plpythonu;

select f_py_greater (l_extendedprice, l_discount) from lineitem limit 10