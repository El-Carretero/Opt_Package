#include "../core/ElementFormula.h"
#include "../core/PyRunner.h"
#include "../tests/TestUtils.h"

#include "testing/OriTestBase.h"

namespace Z {
namespace Tests {
namespace ElementFormulaTests {

namespace {
class TestParam : public Z::Parameter
{
public:
    TestParam(Ori::Testing::TestBase *test, const QString& name): Z::Parameter(Z::Dims::none(), name), test(test) {}
    ~TestParam() override {
        TEST_LOG("~TestParam() " + alias())
        SET_TEST_DATA(QString("param destructor %1").arg(alias()), true);
    }
    Ori::Testing::TestBase *test;
};

void initNonUnityMatrices(ElemFormula& elem)
{
    elem.setFormula(R"PY(
from rezonator import Matrix

def calc_matrix(elem):
    return {'Mt': Matrix(2, 3, 4, 5), 'Ms': Matrix(6, 7, 8, 9)}
)PY");
    elem.calcMatrix("prepare error test");
}
}

#define ASSERT_PARAM_DESTRUCTED(param_alias) \
    ASSERT_IS_TRUE(test->data()[QString("param destructor %1").arg(param_alias)].toBool())

#define ADD_PARAM(name, value) \
    auto p_##name = new TestParam(test, #name);\
    p_##name->setValue(value);\
    elem.addParam(p_##name);

#define ASSERT_MATRIX(ts, a, b, c, d)\
    TEST_LOG(elem.failReason())\
    ASSERT_IS_FALSE(elem.failed())\
    ASSERT_EQ_DBL(elem.M##ts().A.real(), a)\
    ASSERT_EQ_DBL(elem.M##ts().B.real(), b)\
    ASSERT_EQ_DBL(elem.M##ts().C.real(), c)\
    ASSERT_EQ_DBL(elem.M##ts().D.real(), d)\
    ASSERT_EQ_DBL(elem.M##ts().A.imag(), 0)\
    ASSERT_EQ_DBL(elem.M##ts().B.imag(), 0)\
    ASSERT_EQ_DBL(elem.M##ts().C.imag(), 0)\
    ASSERT_EQ_DBL(elem.M##ts().D.imag(), 0)

#define CALC_TEST_MATRIX(code)\
    elem.setFormula(code);\
    elem.calcMatrix("test");

#define INIT_NON_UNITY_MATRICES\
    initNonUnityMatrices(elem);\
    ASSERT_MATRIX(t, 2, 3, 4, 5)\
    ASSERT_MATRIX(s, 6, 7, 8, 9)

#define ASSERT_ALL_MATRICES_ARE_UNITY\
    ASSERT_MATRIX_IS_UNITY(elem.Mt())\
    ASSERT_MATRIX_IS_UNITY(elem.Ms())\
    ASSERT_MATRIX_IS_UNITY(elem.Mt_inv())\
    ASSERT_MATRIX_IS_UNITY(elem.Ms_inv())

#define ASSERT_ERROR(err) {}\
    TEST_LOG(elem.failReason())\
    ASSERT_IS_TRUE(elem.failed())\
    QString expected_error(err);\
    if (!expected_error.isEmpty())\
        ASSERT_EQ_STR(elem.failReason(), expected_error)


TEST_METHOD(can_calculate_matrix)
{
    ElemFormula elem;

    ADD_PARAM(a, 1)
    ADD_PARAM(b, 2)
    ADD_PARAM(c, 3)
    ADD_PARAM(d, 4)

    CALC_TEST_MATRIX(R"PY(
from rezonator import Matrix

def calc_matrix(elem):
    a = elem.param('a')
    b = elem.param('b')
    c = elem.param('c')
    d = elem.param('d')
    return {
        'Mt': Matrix(a, b, c, d),
        'Ms': Matrix(10*a, 10*b, 10*c, 10*d),
    }
)PY")

    ASSERT_MATRIX(t, 1, 2, 3, 4)
    ASSERT_MATRIX(s, 10, 20, 30, 40)
}

TEST_METHOD(matrix_must_be_unity_when_empty_formula)
{
    ElemFormula elem;
    INIT_NON_UNITY_MATRICES
    CALC_TEST_MATRIX("")
    ASSERT_ERROR("Failed to get function calc_matrix")
    ASSERT_IS_TRUE(elem.errorLog().join('\n').contains("has no attribute 'calc_matrix'"))
    ASSERT_ALL_MATRICES_ARE_UNITY
}

TEST_METHOD(matrix_must_be_unity_when_callback_removed)
{
    ElemFormula elem;
    INIT_NON_UNITY_MATRICES
    CALC_TEST_MATRIX("from rezonator import Matrix\nvalue = 42\n")
    ASSERT_ERROR("Failed to get function calc_matrix")
    ASSERT_IS_TRUE(elem.errorLog().join('\n').contains("has no attribute 'calc_matrix'"))
    ASSERT_ALL_MATRICES_ARE_UNITY
}

TEST_METHOD(matrix_must_be_unity_when_invalid_formula)
{
    ElemFormula elem;
    INIT_NON_UNITY_MATRICES
    CALC_TEST_MATRIX(R"PY(
from rezonator import Matrix

def calc_matrix(elem):
    return {'Mt': Matrix(1, 2, 3, unknown_func(4)), 'Ms': Matrix()}
)PY")
    ASSERT_ERROR("Failed to call function (function: calc_matrix)")
    ASSERT_IS_TRUE(elem.errorLog().join('\n').contains("NameError: name 'unknown_func' is not defined"))
    ASSERT_ALL_MATRICES_ARE_UNITY
}

TEST_CASE_METHOD(matrix_must_be_unity_when_no_abcd, const char* missedName)
{
    ElemFormula elem;
    INIT_NON_UNITY_MATRICES
    QString code(R"PY(
from rezonator import Matrix

def calc_matrix(elem):
    At = 5
    Bt = 6
    Ct = 7
    Dt = 8
    As = 9
    Bs = 10
    Cs = 11
    Ds = 12
    return {'Mt': Matrix(At, Bt, Ct, Dt), 'Ms': Matrix(As, Bs, Cs, Ds)}
)PY");
    // Remove only the coefficient's definition, retaining its use in the matrix.
    code.replace(QString("%1 =").arg(missedName), "dummy =");
    CALC_TEST_MATRIX(code)
    ASSERT_ERROR("Failed to call function (function: calc_matrix)")
    ASSERT_IS_TRUE(elem.errorLog().join('\n').contains(
        QString("NameError: name '%1' is not defined").arg(missedName)))
    ASSERT_ALL_MATRICES_ARE_UNITY
}
TEST_CASE(matrix_must_be_unity_when_no_at, matrix_must_be_unity_when_no_abcd, "At")
TEST_CASE(matrix_must_be_unity_when_no_bt, matrix_must_be_unity_when_no_abcd, "Bt")
TEST_CASE(matrix_must_be_unity_when_no_ct, matrix_must_be_unity_when_no_abcd, "Ct")
TEST_CASE(matrix_must_be_unity_when_no_dt, matrix_must_be_unity_when_no_abcd, "Dt")
TEST_CASE(matrix_must_be_unity_when_no_as, matrix_must_be_unity_when_no_abcd, "As")
TEST_CASE(matrix_must_be_unity_when_no_bs, matrix_must_be_unity_when_no_abcd, "Bs")
TEST_CASE(matrix_must_be_unity_when_no_cs, matrix_must_be_unity_when_no_abcd, "Cs")
TEST_CASE(matrix_must_be_unity_when_no_ds, matrix_must_be_unity_when_no_abcd, "Ds")

TEST_CASE_METHOD(matrix_must_be_unity_when_no_result, const char* result)
{
    ElemFormula elem;
    INIT_NON_UNITY_MATRICES
    CALC_TEST_MATRIX(QString("def calc_matrix(elem):\n    return %1\n").arg(result))
    ASSERT_ERROR("Function calc_matrix returned no matrices")
    ASSERT_ALL_MATRICES_ARE_UNITY
}
TEST_CASE(matrix_must_be_unity_when_none_returned, matrix_must_be_unity_when_no_result, "None")
TEST_CASE(matrix_must_be_unity_when_empty_list_returned, matrix_must_be_unity_when_no_result, "[]")

TEST_METHOD(params_in_formula_must_be_in_si_units)
{
    ElemFormula elem;
    auto p = new Z::Parameter(Z::Dims::linear(), "a");
    p->setValue(10_cm);
    elem.addParam(p);
    CALC_TEST_MATRIX(R"PY(
from rezonator import Matrix

def calc_matrix(elem):
    a = elem.param('a')
    return {'Mt': Matrix(a, a, a, a), 'Ms': Matrix(a, a, a, a)}
)PY")
    ASSERT_MATRIX(t, 0.1, 0.1, 0.1, 0.1)
    ASSERT_MATRIX(s, 0.1, 0.1, 0.1, 0.1)
}

TEST_METHOD(python_state_persists_between_calls_and_resets_on_reload)
{
    PyRunner py;
    py.moduleName = "test_element_formula_state";
    py.funcNames = { "next_value" };
    py.code = R"PY(
counter = 0

def next_value():
    global counter
    counter += 1
    return {'value': counter}
)PY";
    ASSERT_IS_TRUE(py.load())
    const PyRunner::ResultSpec spec {{ "value", PyRunner::ftNumber }};
    for (double expected : {1.0, 2.0}) {
        auto result = py.run("next_value", {}, spec);
        ASSERT_IS_TRUE(result.has_value())
        ASSERT_EQ_INT(result->size(), 1)
        ASSERT_EQ_DBL(result->first()["value"].toDouble(), expected)
    }

    ASSERT_IS_TRUE(py.load())
    auto result = py.run("next_value", {}, spec);
    ASSERT_IS_TRUE(result.has_value())
    ASSERT_EQ_INT(result->size(), 1)
    ASSERT_EQ_DBL(result->first()["value"].toDouble(), 1.0)
}

//------------------------------------------------------------------------------

TEST_GROUP("ElementFormula",
           ADD_TEST(can_calculate_matrix),
           ADD_TEST(matrix_must_be_unity_when_empty_formula),
           ADD_TEST(matrix_must_be_unity_when_callback_removed),
           ADD_TEST(matrix_must_be_unity_when_invalid_formula),
           ADD_TEST(matrix_must_be_unity_when_no_at),
           ADD_TEST(matrix_must_be_unity_when_no_bt),
           ADD_TEST(matrix_must_be_unity_when_no_ct),
           ADD_TEST(matrix_must_be_unity_when_no_dt),
           ADD_TEST(matrix_must_be_unity_when_no_as),
           ADD_TEST(matrix_must_be_unity_when_no_bs),
           ADD_TEST(matrix_must_be_unity_when_no_cs),
           ADD_TEST(matrix_must_be_unity_when_no_ds),
           ADD_TEST(matrix_must_be_unity_when_none_returned),
           ADD_TEST(matrix_must_be_unity_when_empty_list_returned),
           ADD_TEST(params_in_formula_must_be_in_si_units),
           ADD_TEST(python_state_persists_between_calls_and_resets_on_reload),
           )

} // namespace ElementFormulaTests
} // namespace Tests
} // namespace Z
