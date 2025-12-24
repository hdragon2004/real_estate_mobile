import React, { useEffect, useState } from 'react';
import { Layout, Table, Button, Tag, Space, Modal, Select, message } from 'antd';
import Sidebar from '../../components/Sidebar';
import axiosPrivate from '../../api/axiosPrivate';
import { unwrapListResponse } from '../../api/responseHelper';
import MessageProvider from '../../components/MessageProvider';


const { Content } = Layout;

const UsersPage = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const { showMessage, contextHolder } = MessageProvider();

  useEffect(() => {
    const fetchUsers = async () => {
      try {
        const res = await axiosPrivate.get('/api/users');
        const usersData = unwrapListResponse(res);
        setUsers(usersData);
      } catch (err) {
        const errorData = err.response?.data;
        const errorMessage = errorData?.message || errorData || 'Không thể tải danh sách người dùng';
        showMessage.error(errorMessage);
      } finally {
        setLoading(false);
      }
    };
    fetchUsers();
  }, []);

  const handleToggleLock = async (userId, isLocked) => {
    try {
      await axiosPrivate.put(`/api/admin/users/${userId}/lock`, isLocked);
      setUsers(users => users.map(u => u.id === userId ? { ...u, isLocked } : u));
      showMessage.success(isLocked ? 'Đã khóa tài khoản' : 'Đã mở khóa tài khoản');
    } catch (error) {
      console.error('Error toggling lock:', error);
      const errorMessage = error.response?.data?.message || error.response?.data || 'Lỗi thao tác';
      showMessage.error(errorMessage);
    }
  };

  const handleChangeRole = async (userId, newRole) => {
    try {
      const response = await axiosPrivate.put(`/api/admin/users/${userId}/role`, { role: newRole });
      setUsers(users => users.map(u => u.id === userId ? { ...u, role: newRole } : u));
      showMessage.success('Đã đổi quyền thành công');
    } catch (error) {
      console.error('Error changing role:', error);
      const errorMessage = error.response?.data?.message || error.response?.data || 'Lỗi đổi quyền';
      showMessage.error(errorMessage);
    }
  };

  const handleDelete = async (userId) => {
    if (window.confirm('Bạn có chắc chắn muốn xóa người dùng này?')) {
      try {
        const response = await axiosPrivate.delete(`/api/admin/users/${Number(userId)}`);
        if (response.status === 200 || response.status === 204) {
          setUsers(users => users.filter(u => u.id !== userId));
          showMessage.success('Đã xoá người dùng thành công');
        }
      } catch (error) {
        console.error('Error deleting user:', error);
        const errorMessage = error.response?.data?.message || error.response?.data || 'Không thể xóa người dùng';
        showMessage.error(errorMessage);
      }
    }
  };

  const columns = [
    { title: 'Tên', dataIndex: 'name', key: 'name' },
    { title: 'Email', dataIndex: 'email', key: 'email' },
    { title: 'Số điện thoại', dataIndex: 'phone', key: 'phone' },
    { title: 'Role', dataIndex: 'role', key: 'role', render: (role, record) => (
      <Select value={role} style={{ width: 150 }} onChange={val => handleChangeRole(record.id, val)}>
        <Select.Option value="User">User</Select.Option>
        <Select.Option value="Admin">Admin</Select.Option>
        <Select.Option value="Pro_1">Pro_1</Select.Option>
        <Select.Option value="Pro_3">Pro_3</Select.Option>
        <Select.Option value="Pro_12">Pro_12</Select.Option>
      </Select>
    ) },
    { title: 'Trạng thái', dataIndex: 'isLocked', key: 'isLocked', render: isLocked => (
      <Tag color={isLocked ? 'red' : 'green'}>{isLocked ? 'Đã khoá' : 'Hoạt động'}</Tag>
    ) },
    {
      title: 'Hành động',
      key: 'action',
      render: (_, record) => (
        <Space>
          <Button onClick={() => handleToggleLock(record.id, !record.isLocked)}>
            {record.isLocked ? 'Mở khoá' : 'Khoá'}
          </Button>
          <Button danger onClick={() => handleDelete(record.id)}>Xoá</Button>
        </Space>
      ),
    },
  ];

  return (
    <Layout style={{ minHeight: '100vh'}}>
      {contextHolder}
      <Sidebar selectedKey="/admin/users" />
      <Layout>
        <Content style={{ margin: '24px 16px 0', background: '#141414' }}>
          <h1 style={{ color: '#fff', fontSize: 24, fontWeight: 700 }}>Quản lý người dùng</h1>
          <Table columns={columns} dataSource={users} loading={loading} rowKey="id" style={{ marginTop: 24 }} />
        </Content>
      </Layout>
    </Layout>
  );
};

export default UsersPage; 