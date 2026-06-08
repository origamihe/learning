package io.github.origamihe.learning.handler;

import org.apache.ibatis.type.BaseTypeHandler;
import org.apache.ibatis.type.JdbcType;
import org.apache.ibatis.type.MappedJdbcTypes;

import java.sql.*;

@MappedJdbcTypes(JdbcType.ARRAY)
public class StringArrayTypeHandler extends BaseTypeHandler<String> {

    @Override
    public void setNonNullParameter(PreparedStatement ps, int i, String parameter, JdbcType jdbcType)
            throws SQLException {
        String[] array = parameter.split(",");
        Array sqlArray = ps.getConnection().createArrayOf("text", array);
        ps.setArray(i, sqlArray);
    }

    @Override
    public String getNullableResult(ResultSet rs, String columnName) throws SQLException {
        Array array = rs.getArray(columnName);
        if (rs.wasNull() || array == null) {
            return null;
        }
        return arrayToString(array);
    }

    @Override
    public String getNullableResult(ResultSet rs, int columnIndex) throws SQLException {
        Array array = rs.getArray(columnIndex);
        if (rs.wasNull() || array == null) {
            return null;
        }
        return arrayToString(array);
    }

    @Override
    public String getNullableResult(CallableStatement cs, int columnIndex) throws SQLException {
        Array array = cs.getArray(columnIndex);
        if (cs.wasNull() || array == null) {
            return null;
        }
        return arrayToString(array);
    }

    private String arrayToString(Array array) throws SQLException {
        try {
            String[] arr = (String[]) array.getArray();
            if (arr == null) {
                return null;
            }
            return String.join(",", arr);
        } catch (SQLException e) {
            return null;
        }
    }
}