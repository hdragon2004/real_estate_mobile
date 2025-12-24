import React, { useEffect, useState } from 'react';
import { Layout, Row, Col, Card, Statistic, Spin, message, Table, Tag } from 'antd';
import Sidebar from '../../components/Sidebar';
import axiosPrivate from '../../api/axiosPrivate';
import { unwrapResponse, unwrapListResponse } from '../../api/responseHelper';
import { useNavigate } from 'react-router-dom';

const { Content } = Layout;

const AdminDashboard = () => {
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalPosts: 0,
    totalReports: 0,
    pendingApprovals: 0
  });
  const [loading, setLoading] = useState(true);
  const [recentPosts, setRecentPosts] = useState([]);
  const [recentUsers, setRecentUsers] = useState([]);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [statsRes, postsRes, usersRes, notificationsRes, messagesRes, savedSearchesRes, appointmentsRes] = await Promise.all([
          axiosPrivate.get('/api/admin/stats'),
          axiosPrivate.get('/api/admin/recent-posts'),
          axiosPrivate.get('/api/admin/recent-users'),
          axiosPrivate.get('/api/admin/notifications').catch(() => ({ data: { data: [] } })),
          axiosPrivate.get('/api/admin/messages').catch(() => ({ data: { data: [] } })),
          axiosPrivate.get('/api/admin/saved-searches').catch(() => ({ data: { data: [] } })),
          axiosPrivate.get('/api/admin/appointments').catch(() => ({ data: { data: [] } }))
        ]);
        
        const statsData = unwrapResponse(statsRes);
        const notificationsData = unwrapListResponse(notificationsRes);
        const messagesData = unwrapListResponse(messagesRes);
        const savedSearchesData = unwrapListResponse(savedSearchesRes);
        const appointmentsData = unwrapListResponse(appointmentsRes);
        const postsData = unwrapListResponse(postsRes);
        const usersData = unwrapListResponse(usersRes);
        
        setStats({
          ...(statsData || {}),
          totalNotifications: notificationsData.length,
          totalMessages: messagesData.length,
          totalSavedSearches: savedSearchesData.length,
          totalAppointments: appointmentsData.length
        });
        setRecentPosts(postsData);
        setRecentUsers(usersData);
      } catch (err) {
        console.error('Error fetching dashboard data:', err);
        const errorData = err.response?.data;
        const errorMessage = errorData?.message || errorData || 'Không thể tải dữ liệu thống kê';
        message.error(errorMessage);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  const recentPostsColumns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 80 },
    { 
      title: 'Tiêu đề', 
      dataIndex: 'title', 
      key: 'title',
      ellipsis: true,
      render: (text, record) => (
        <a onClick={() => navigate(`/chi-tiet/${record.id}`)} style={{ color: '#1890ff' }}>
          {text}
        </a>
      )
    },
    { title: 'Người đăng', dataIndex: ['user', 'name'], key: 'user' },
    { 
      title: 'Trạng thái', 
      dataIndex: 'isApproved', 
      key: 'isApproved',
      render: (isApproved) => (
        <Tag color={isApproved ? 'green' : 'orange'}>
          {isApproved ? 'Đã duyệt' : 'Chờ duyệt'}
        </Tag>
      )
    },
  ];

  const recentUsersColumns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 80 },
    { title: 'Tên', dataIndex: 'name', key: 'name' },
    { title: 'Email', dataIndex: 'email', key: 'email' },
    { 
      title: 'Role', 
      dataIndex: 'role', 
      key: 'role',
      render: (role) => <Tag color="blue">{role}</Tag>
    },
  ];

  return (
    <Layout style={{ minHeight: '100vh'}}>
      <Sidebar selectedKey="/admin" />
      <Layout>
        <Content style={{ margin: '24px 16px 0px', background: '#141414'}}>
          <h1 style={{ color: '#fff', fontSize: 28, fontWeight: 700 }}>Dashboard</h1>
          {loading ? (
            <Spin size="large" />
          ) : (
            <>
              <Row gutter={16} style={{ marginTop: 24 }}>
                <Col span={6}>
                  <Card>
                    <Statistic title="Tổng người dùng" value={stats.totalUsers} styles={{ content: { color: '#1890ff' } }} />
                  </Card>
                </Col>
                <Col span={6}>
                  <Card>
                    <Statistic title="Tổng bài viết" value={stats.totalPosts} styles={{ content: { color: '#52c41a' } }} />
                  </Card>
                </Col>
                <Col span={6}>
                  <Card>
                    <Statistic title="Báo cáo" value={stats.totalReports} styles={{ content: { color: '#faad14' } }} />
                  </Card>
                </Col>
                <Col span={6}>
                  <Card>
                    <Statistic title="Chờ duyệt" value={stats.pendingApprovals} styles={{ content: { color: '#ff4d4f' } }} />
                  </Card>
                </Col>
              </Row>
              <Row gutter={16} style={{ marginTop: 16 }}>
                <Col span={6}>
                  <Card>
                    <Statistic title="Thông báo" value={stats.totalNotifications || 0} styles={{ content: { color: '#722ed1' } }} />
                  </Card>
                </Col>
                <Col span={6}>
                  <Card>
                    <Statistic title="Tin nhắn" value={stats.totalMessages || 0} styles={{ content: { color: '#13c2c2' } }} />
                  </Card>
                </Col>
                <Col span={6}>
                  <Card>
                    <Statistic title="Khu vực tìm kiếm" value={stats.totalSavedSearches || 0} styles={{ content: { color: '#eb2f96' } }} />
                  </Card>
                </Col>
                <Col span={6}>
                  <Card>
                    <Statistic title="Lịch hẹn" value={stats.totalAppointments || 0} styles={{ content: { color: '#f5222d' } }} />
                  </Card>
                </Col>
              </Row>
              <Row gutter={16} style={{ marginTop: 24 }}>
                <Col span={12}>
                  <Card title="Bài viết gần đây" style={{ background: '#1f1f1f' }}>
                    <Table 
                      columns={recentPostsColumns} 
                      dataSource={recentPosts} 
                      rowKey="id"
                      pagination={false}
                      size="small"
                      style={{ background: '#1f1f1f' }}
                    />
                  </Card>
                </Col>
                <Col span={12}>
                  <Card title="Người dùng mới" style={{ background: '#1f1f1f' }}>
                    <Table 
                      columns={recentUsersColumns} 
                      dataSource={recentUsers} 
                      rowKey="id"
                      pagination={false}
                      size="small"
                      style={{ background: '#1f1f1f' }}
                    />
                  </Card>
                </Col>
              </Row>
            </>
          )}
        </Content>
      </Layout>
    </Layout>
  );
};

export default AdminDashboard; 