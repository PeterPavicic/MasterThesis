def get_wealth_network(gamma: float):

    """
    Creates a model wealth network for the specific trading cost multiplier gamma given as an argument
    Returns the model wealth network
    """
    # (timeToMaturity, Price) vector
    Obs = Input(shape=(N,1+m))
    # (S_t - S_{t-1}) vector, i.e. price increments
    Incr = Input(shape=(N,m))
    inputs = [Obs,Incr]

    # estimating wealth with NN1
    first_price = Lambda(lambda x: x[:,0,1:(m+1)])(Obs)
    V0 = pi(first_price)

    # initial previous hedge = zero
    prev_h = Lambda(lambda x: tf.zeros((tf.shape(x)[0], 1)), output_shape=(1,))(Obs)
    # initial previous price = S_0
    prev_price = Lambda(lambda x: x[:,0,1:(1+m)])(Obs) 

    # store hedging positions
    h_slices = []

    # calculate hedging positions
    for t in range(N):
        # t-th (TTM, S_t) vector
        obsSlice = Lambda(
            lambda x, i: x[:, i, :],
            arguments={"i": t}, # ensures correct functioning of for loop
            output_shape=(1+m,)
        )(Obs)

        # concatenate with previous hedge and previous price
        obs_with_p_hedge = Concatenate(axis=1)([obsSlice, prev_h, prev_price])

        H = hedge(obs_with_p_hedge)
        h_slices.append(Reshape((1,1))(H)) # store H (reshape for convenience)

        # update for next iteration
        prev_h = H
        prev_price = Lambda(lambda x,i: x[:,i,1:(1+m)],
                            arguments={'i': t},
                            output_shape=(m,))(Obs)

    # vector/layer of all positions H
    H = Concatenate(axis=1)(h_slices)

    # compute gains/losses from trading
    Incr = Flatten()(Incr)
    H_flat = Flatten()(H)
    Gain = Dot(axes=1)([H_flat,Incr])
    wealth_gain = Add()([V0, Gain]) # add gains/losses to V0

    # NOTE: This is where trading costs are calculated

    # compute variables for trading costs
    H_prev = Lambda(lambda x: x[:, :-1, :])(H)
    H_curr = Lambda(lambda x: x[:, 1: , :])(H)
    dH = Subtract()([H_curr, H_prev])
    S_prev = Lambda(lambda x: x[:, :-1, 1:(m+1)])(Obs)

    # compute per-step trading cost
    cost_per_step = Multiply()([dH, S_prev])
    absolute_cost_per_step = Lambda(lambda x: tf.abs(x))(cost_per_step)

    # compute total trading cost
    cost_sum = Lambda(lambda x: tf.reduce_sum(x, axis=1, keepdims=True))(absolute_cost_per_step) # this line has caused me great pain
    cost = Lambda(lambda x: gamma * x)(cost_sum)
    cost_flat = Flatten()(cost)

    # compute total wealth: V0 + Gain - Total Cost
    total_wealth = Subtract()([wealth_gain, cost_flat])

    # compile model
    wealth = Model(inputs=inputs, outputs=total_wealth)
    wealth.compile(optimizer='adam',loss='mean_squared_error')

    # NOTE: Included for debugging purposes, summary is very large
    # print("\n\nNetwork for terminal wealth:") # it is large and one shouldn't look at it!
    # model_wealth.summary()
    return wealth


# NOTE: This is a test line



