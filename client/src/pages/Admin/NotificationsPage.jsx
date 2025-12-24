import React, { useEffect, useState } from 'react';
import { Layout, Table, Tag, Space, Button, Modal, Descriptions, Select } from 'antd';
import Sidebar from '../../components/Sidebar';
import axiosPrivate from '../../api/axiosPrivate';
import { unwrapListResponse } from '../../api/responseHelper';
import MessageProvider from '../../components/MessageProvider';

const { Content } = Layout;
const { Option } = Select;

const NotificationsPage = () => {
  const [notifications, setNotifications] = useState([]);
  const [loading, setLoading] = useState(true);
  const [detail, setDetail] = useState(null);
  const [filterType, setFilterType] = useState('all');
  const { showMessage, contextHolder } = MessageProvider();

  useEffect(() => {
    fetchNotifications();
  }, [filterType]);

  const fetchNotifications = async () => {
      try {
        const res = await axiosPrivate.get('/api/admin/notifications');
        let data = unwrapListResponse(res);
        
        if (filterType !== 'all') {
          data = data.filter(n => n.type === filterType);
        }
        
        setNotifications(data);
      } catch (error) {
        console.error('Error fetching notifications:', error);
        const errorData = error.response?.data;
        const errorMessage = errorData?.message || errorData || 'Không thể tải danh sách thông báo';
        showMessage.error(errorMessage);
      } finally {
        setLoading(false);
      }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Bạn có chắc chắn muốn xóa thông báo này?')) {
      try {
        const response = await axiosPrivate.delete(`/api/notifications/${id}`);
        if (response.status === 200 || response.status === 204) {
          setNotifications(notifications => notifications.filter(n => n.id !== id));
          showMessage.success('Đã xóa thông báo thành công');
        }
      } catch (error) {
        console.error('Error deleting notification:', error);
        const errorMessage = error.response?.data?.message || error.response?.data || 'Không thể xóa thông báo';
        showMessage.error(errorMessage);
      }
    }
  };

  const getTypeColor = (type) => {
    const colors = {
      'approved': 'green',
      'SavedSearch': 'blue',
      'Message': 'purple',
      'Favorite': 'pink',
      'PostPending': 'orange',
      'PostApproved': 'green',
      'Welcome': 'cyan',
      'Reminder': 'gold',
      'expire': 'orange',
      'expired': 'red'
    };
    return colors[type] || 'default';
  };

  const columns = [
    { 
      title: 'ID', 
      dataIndex: 'id', 
      key: 'id', 
      width: 80 
    },
    { 
      title: 'Người dùng', 
      dataIndex: 'userName', 
      key: 'userName',
      render: (text) => <span style={{ color: '#fff' }}>{text || 'N/A'}</span>
    },
    { 
      title: 'Tiêu đề', 
      dataIndex: 'title', 
      key: 'title',
      ellipsis: true,
      render: (text) => <span style={{ color: '#fff' }}>{text}</span>
    },
    { 
      title: 'Loại', 
      dataIndex: 'type', 
      key: 'type',
      render: (type) => (
        <Tag color={getTypeColor(type)}>{type || 'N/A'}</Tag>
      )
    },
    { 
      title: 'Bài viết', 
      dataIndex: 'postTitle', 
      key: 'postTitle',
      ellipsis: true,
      render: (text) => <span style={{ color: '#fff' }}>{text || 'N/A'}</span>
    },
    { 
      title: 'Trạng thái', 
      dataIndex: 'isRead', 
      key: 'isRead',
      render: (isRead) => (
        <Tag color={isRead ? 'green' : 'orange'}>
          {isRead ? 'Đã đọc' : 'Chưa đọc'}
        </Tag>
      )
    },
    { 
      title: 'Thời gian', 
      dataIndex: 'createdAt', 
      key: 'createdAt',
      render: (date) => (
        <span style={{ color: '#fff' }}>
          {date ? new Date(date).toLocaleString('vi-VN') : 'N/A'}
        </span>
      )
    },
    {
      title: 'Hành động',
      key: 'action',
      width: 150,
      render: (_, record) => (
        <Space>
          <Button onClick={() => setDetail(record)}>Xem</Button>
          <Button danger onClick={() => handleDelete(record.id)}>Xóa</Button>
        </Space>
      ),
    },
  ];

  return (
    <Layout style={{ minHeight: '100vh' }}>
      {contextHolder}
      <Sidebar selectedKey="/admin/notifications" />
      <Layout>
        <Content style={{ margin: '24px 16px 0', background: '#141414' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
            <h1 style={{ color: '#fff', fontSize: 24, fontWeight: 700 }}>Quản lý thông báo</h1>
            <Select
              value={filterType}
              onChange={setFilterType}
              style={{ width: 200 }}
            >
              <Option value="all">Tất cả</Option>
              <Option value="approved">Đã duyệt</Option>
              <Option value="SavedSearch">Khu vực yêu thích</Option>
              <Option value="Message">Tin nhắn</Option>
              <Option value="Reminder">Nhắc lịch</Option>
              <Option value="Favorite">Yêu thích</Option>
            </Select>
          </div>
          <Table 
            columns={columns} 
            dataSource={notifications} 
            loading={loading} 
            rowKey="id" 
            style={{ marginTop: 12 }}
            pagination={{ pageSize: 20 }}
          />
          <Modal 
            open={!!detail} 
            onCancel={() => setDetail(null)} 
            footer={null} 
            title="Chi tiết thông báo"
            width={600}
          >
            {detail && (
              <Descriptions bordered column={1} size="small">
                <Descriptions.Item label="ID">{detail.id}</Descriptions.Item>
                <Descriptions.Item label="Người dùng">
                  {detail.userName || `User ID: ${detail.userId}`}
                </Descriptions.Item>
                <Descriptions.Item label="Tiêu đề">{detail.title}</Descriptions.Item>
                <Descriptions.Item label="Nội dung">{detail.message}</Descriptions.Item>
                <Descriptions.Item label="Loại">
                  <Tag color={getTypeColor(detail.type)}>{detail.type}</Tag>
                </Descriptions.Item>
                <Descriptions.Item label="Bài viết">
                  {detail.postTitle || `Post ID: ${detail.postId || 'N/A'}`}
                </Descriptions.Item>
                <Descriptions.Item label="Saved Search ID">
                  {detail.savedSearchId || 'N/A'}
                </Descriptions.Item>
                <Descriptions.Item label="Appointment ID">
                  {detail.appointmentId || 'N/A'}
                </Descriptions.Item>
                <Descriptions.Item label="Trạng thái">
                  <Tag color={detail.isRead ? 'green' : 'orange'}>
                    {detail.isRead ? 'Đã đọc' : 'Chưa đọc'}
                  </Tag>
                </Descriptions.Item>
                <Descriptions.Item label="Thời gian">
                  {detail.createdAt ? new Date(detail.createdAt).toLocaleString('vi-VN') : 'N/A'}
                </Descriptions.Item>
              </Descriptions>
            )}
          </Modal>
        </Content>
      </Layout>
    </Layout>
  );
};

export default NotificationsPage;

