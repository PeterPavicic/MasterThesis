

# Questions:

- What is the difference between `userPosition` in P\&L subgraph and `netUserBalances` in positions subgraph??



# TODO:
- [ ] Price volume, liquidity measure (spreads)
- [ ] Bid ask spread? How to get it?
- [ ] Proxy for liquidity over time: Amihud illiquidity ratio

- [ ] cross-section of users
- [ ] winners/losers

- [ ] Investor statistics based on IDs:
- [ ] Liquidity providers (and how much they make)
- [ ] Uninformed traders?
- [ ] How many?
- [ ] PnL distribution
- [ ] Algo trader?
- [ ] (Traders across markets?)


- [ ] How many?
- [ ] PnL distribution
- [ ] Algo trader?
- [ ] (Traders across markets?)



Important vim macros:

r macro:
vip:s/.*"\(.*\)"/\1vip:norm A vipgJ$x
g macro:
/=yi[}Op@rdd?"""PiReturns: >>

### NegRiskEvent
Neg Risk Events/Markets
- id
- questionCount
### Condition
id
positionIds
payoutNumerators
payoutDenominator
### FPMM
id
conditionId
