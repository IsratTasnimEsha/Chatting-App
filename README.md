Let's break down the entire explanation into simpler terms, covering each concept step by step.

### Classification with Non-Linear Boundaries

#### 1. **Linear Classifiers**:
- A **linear classifier**, like the **support vector classifier**, tries to draw a straight line (or plane in higher dimensions) to separate data points from two different classes.
- This works well if the data can be separated by a straight line.

#### 2. **Non-Linear Class Boundaries**:
- In some cases, the separation between classes is **not straight**. For instance, the data might be in such a way that a curve is needed to separate the two classes.
- Linear classifiers fail in such cases.

#### 3. **Enlarging the Feature Space**:
- A trick to handle non-linear boundaries is to transform or expand the data into a higher-dimensional space.
- This involves creating new features based on existing ones, like squaring or cubing the values (quadratic, cubic transformations).
- For example, instead of using \(X_1\) and \(X_2\) as features, you can add new features like \(X_1^2\), \(X_2^2\), which help form a non-linear boundary in the original feature space.

#### 4. **Maximization Problem**:
The goal of the support vector classifier is to maximize the margin (distance) between the decision boundary and the closest data points (called **support vectors**). The optimization problem can be written as:

\[
\text{maximize} \quad \beta_0, \beta_{11}, \beta_{12}, \ldots, \beta_{p}, \epsilon_1, \ldots, \epsilon_n, M
\]

This equation essentially means you are trying to find the best values for parameters \( \beta \) (weights for features) and margin \( M \), while keeping the error terms \( \epsilon_i \) small.

#### 5. **Constraints**:
The optimization is subject to the following constraints:

\[
y_i \left( \beta_0 + \sum_{j=1}^{p} \beta_{j1} x_{ij} + \sum_{j=1}^{p} \beta_{j2} x_{ij}^2 \right) \geq M(1 - \epsilon_i),
\]

This ensures that the classifier assigns the correct class \( y_i \) for each data point \( x_i \), while keeping any errors \( \epsilon_i \) within acceptable limits.

There are also additional constraints on the error term:

\[
\sum_{i=1}^{n} \epsilon_i \leq C, \quad \epsilon_i \geq 0,
\]

This means the sum of the errors must stay below a certain threshold \( C \), and each individual error \( \epsilon_i \) cannot be negative (i.e., errors are non-negative).

Finally, there’s a normalization constraint:

\[
\sum_{j=1}^{p} \sum_{k=1}^{2} \beta_{jk}^2 = 1.
\]

This ensures the weights \( \beta \) are normalized.

#### 6. **Support Vector Machine (SVM)**:
An SVM extends the support vector classifier to handle **non-linear decision boundaries**. Instead of working with just the original features, SVM uses **kernels** to transform the data into higher dimensions, where a linear boundary can effectively separate the classes.

### Kernels: The Core Idea

#### 7. **Inner Product**:
- The inner product (or dot product) between two vectors \( a \) and \( b \) is a way to measure their similarity. Mathematically, it's written as:

\[
\langle a, b \rangle = \sum_{i=1}^{r} a_i b_i
\]

For two data points \( x_i \) and \( x_i' \), this is written as:

\[
\langle x_i, x_i' \rangle = \sum_{j=1}^{p} x_{ij} x_{i'j}.
\]

#### 8. **Linear Support Vector Classifier**:
- The decision function of a **linear support vector classifier** is:

\[
f(x) = \beta_0 + \sum_{i=1}^{n} \alpha_i \langle x, x_i \rangle.
\]

This means we calculate the similarity (inner product) between the new data point \( x \) and each of the training data points \( x_i \), and use this to classify the new point.

#### 9. **Support Vectors**:
- Only a few training points (called **support vectors**) are actually used to define the decision boundary. If a point is not a support vector, its \( \alpha_i \) will be zero. So, the function can be simplified as:

\[
f(x) = \beta_0 + \sum_{i \in S} \alpha_i \langle x, x_i \rangle,
\]

where \( S \) is the set of support vectors.

#### 10. **Kernel Trick**:
- In SVM, we replace the inner product \( \langle x, x_i \rangle \) with a **kernel function** \( K(x_i, x_i') \). A kernel function measures the similarity between two data points in some (possibly higher-dimensional) space.

The most basic kernel is the **linear kernel**:

\[
K(x_i, x_i') = \sum_{j=1}^{p} x_{ij} x_{i'j}.
\]

#### 11. **Polynomial Kernel**:
- We can use a **polynomial kernel** to capture more complex relationships between features. It’s written as:

\[
K(x_i, x_i') = (1 + \sum_{j=1}^{p} x_{ij} x_{i'j})^d,
\]

where \( d \) is the degree of the polynomial. This allows the SVM to find more flexible boundaries, like curves or higher-order shapes.

#### 12. **Radial Kernel**:
- Another popular choice is the **radial basis function (RBF) kernel**:

\[
K(x_i, x_i') = \exp\left(-\gamma \sum_{j=1}^{p} (x_{ij} - x_{i'j})^2\right).
\]

This kernel measures the distance between two points and transforms it in such a way that nearby points have a high similarity, and distant points have a low similarity. Here, \( \gamma \) controls how quickly the similarity drops off with distance.

### Summary:

- **Linear Classifiers** work for simple boundaries.
- **Support Vector Machines (SVM)** can handle non-linear boundaries using **kernels** to transform data.
- **Kernels** are functions that calculate similarity between data points in higher dimensions, allowing SVMs to find more complex decision boundaries.
