# NHL-project

From 2019 to 2021, the National Hockey League (NHL) has compiled performance statistics for its 938 players. As with any other professional sports league, a player's salary is primarily determined by performance, meaning that we expect the best-performing players to receive the highest salaries.

For my final project, I decided to create regression models to predict an NHL player's salary based on his performance statistics. Some of these performance statistics include: goals, assists, points, plus-minus, time on ice, as well as several advanced metrics, such as Corsi, Fenwick, expected plus-minus, and PDO (see codebook for detailed description of each variable). Player salaries range from \$700,000 to \$12,500,000.

Using data found on the NHL website, Spotrac, and Hockey Reference, I was able to compile each player's performance statistics, salary, and advanced metrics. 

The three predictive models utilized are boosted tree, random forest, and k-nearest neighbors. Each of these three models was created for forwards and defensemen (therefore 6 models in total), since NHL teams generally award forwards and defensemen salaries based on different performance metrics. Forwards are more highly paid than defensemen. By way of example, the average salary for the five most highly paid forwards is \$11.5 million, while the average salary for the five most highly paid defensemen is only \$9.8 million.